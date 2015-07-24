require 'miq_apache'
module MiqWebServerWorkerMixin
  extend ActiveSupport::Concern

  BINDING_ADDRESS = Rails.env.production? ? "127.0.0.1" : "0.0.0.0"

  included do
    class << self
      attr_accessor :registered_ports
    end

    def self.binding_address
      BINDING_ADDRESS
    end

    def self.rails_server
      VMDB::Config.new("vmdb").config.fetch_path(:server, :rails_server) || "thin"
    end

    def self.build_command_line(*params)
      params = params.first || {}

      defaults = {
        :Port        => 3000,
        :Host        => binding_address,
        :environment => Rails.env.to_s,
        :app         => Vmdb::Application
      }

      params = defaults.merge(params)
      params[:pid] = pid_file(params[:Port]).to_s

      # Rack::Server options:

      # Options may include:
      # * :app
      #     a rack application to run (overrides :config)
      # * :config
      #     a rackup configuration file path to load (.ru)
      # * :environment
      #     this selects the middleware that will be wrapped around
      #     your application. Default options available are:
      #       - development: CommonLogger, ShowExceptions, and Lint
      #       - deployment: CommonLogger
      #       - none: no extra middleware
      #     note: when the server is a cgi server, CommonLogger is not included.
      # * :server
      #     choose a specific Rack::Handler, e.g. cgi, fcgi, webrick
      # * :daemonize
      #     if true, the server will daemonize itself (fork, detach, etc)
      # * :pid
      #     path to write a pid file after daemonize
      # * :Host
      #     the host address to bind to (used by supporting Rack::Handler)
      # * :Port
      #     the port to bind to (used by supporting Rack::Handler)
      # * :AccessLog
      #     webrick access log options (or supporting Rack::Handler)
      # * :debug
      #     turn on debug output ($DEBUG = true)
      # * :warn
      #     turn on warnings ($-w = true)
      # * :include
      #     add given paths to $LOAD_PATH
      # * :require
      #     require the given libraries
      params
    end

    def self.all_ports_in_use
      server_scope.select(&:enabled_or_running?).collect(&:port)
    end

    def self.build_uri(port)
      URI::HTTP.build(:host => binding_address, :port => port).to_s
    end

    def self.sync_workers
      # TODO: add an at_exit to remove all registered ports and gracefully stop apache
      self.registered_ports ||= []

      workers = find_current_or_starting
      current = workers.length
      desired = self.has_required_role? ? self.workers : 0
      result  = {:adds => [], :deletes => []}
      ports = all_ports_in_use

      # TODO: This tracking of adds/deletes of pids and ports is not DRY
      ports_hash = {:deletes => [], :adds => []}

      if current != desired
        _log.info("Workers are being synchronized: Current #: [#{current}], Desired #: [#{desired}]")

        if desired > current && enough_resource_to_start_worker?
          (desired - current).times do
            port = reserve_port(ports)
            _log.info("Reserved port=#{port}, Current ports in use: #{ports.inspect}")
            ports << port
            ports_hash[:adds] << port
            w = start_worker(:uri => build_uri(port))
            result[:adds] << w.pid
          end
        elsif desired < current
          workers = workers.to_a
          (current - desired).times do
            w = workers.pop
            port = w.port
            ports.delete(port)
            ports_hash[:deletes] << port

            _log.info("Unreserved port=#{port}, Current ports in use: #{ports.inspect}")
            result[:deletes] << w.pid
            w.stop
          end
        end
      end

      modify_apache_ports(ports_hash) if MiqEnvironment::Command.supports_apache?

      result
    end

    def self.pid_file(port)
      Rails.root.join("tmp/pids/rails_server.#{port}.pid")
    end

    def pid_file
      @pid_file ||= self.class.pid_file(port)
    end

    def self.install_apache_proxy_config
      options = {
        :member_file    => self::BALANCE_MEMBER_CONFIG_FILE,
        :redirects_file => self::REDIRECTS_CONFIG_FILE,
        :method         => self::LB_METHOD,
        :redirects      => self::REDIRECTS,
        :cluster        => self::CLUSTER,
      }

      _log.info("[#{options.inspect}")
      MiqApache::Conf.install_default_config(options)
    end

    def self.modify_apache_ports(ports_hash)
      return unless MiqEnvironment::Command.supports_apache?
      adds    = Array(ports_hash[:adds])
      deletes = Array(ports_hash[:deletes])

      # Remove any already registered
      adds -= self.registered_ports

      return false if adds.empty? && deletes.empty?

      conf = MiqApache::Conf.instance(self::BALANCE_MEMBER_CONFIG_FILE)

      unless adds.empty?
        _log.info("Adding port(s) #{adds.inspect}")
        conf.add_ports(adds)
      end

      unless deletes.empty?
        _log.info("Removing port(s) #{deletes.inspect}")
        conf.remove_ports(deletes)
      end

      saved = conf.save
      if saved
        self.registered_ports += adds
        self.registered_ports -= deletes

        # Update the apache load balancer regardless but only restart apache
        # when adding a new port to the balancer.
        MiqServer.my_server.queue_restart_apache unless adds.empty?
        _log.info("Added/removed port(s) #{adds.inspect}/#{deletes.inspect}, registered ports after #{self.registered_ports.inspect}")
      end
      saved
    end

    def self.reserve_port(ports)
      index = 0
      loop do
        port = self::STARTING_PORT + index
        return port unless ports.include?(port)
        index += 1
      end
    end

    def command_line_params
      params = super
      params[:Port] = port if port.kind_of?(Numeric)
      params
    end

    def start
      delete_pid_file
      ENV['PORT'] = port.to_s
      ENV['MIQ_GUID'] = guid
      super
    end

    def terminate
      # HACK: Cannot call exit properly from UiWorker nor can we Process.kill('INT', ...) from inside the worker
      # Hence, this is an external mechanism for terminating this worker.

      begin
        _log.info("Terminating #{format_full_log_msg}, status [#{status}]")
        Process.kill("TERM", pid)
        # TODO: Variablize and clean up this 10-second-max loop of waiting on Worker to gracefully shut down
        10.times do
          unless MiqProcess.alive?(pid)
            update_attributes(:stopped_on => Time.now.utc, :status => MiqWorker::STATUS_STOPPED)
            break
          end
          sleep 1
        end
      rescue Errno::ESRCH
        _log.warn("#{format_full_log_msg} has been killed")
      rescue => err
        _log.warn("#{format_full_log_msg} has been killed, but with the following error: #{err}")
      end

      kill if MiqProcess.alive?(pid)
    end

    def kill
      deleted_worker = super
      delete_pid_file
      deleted_worker
    end

    def delete_pid_file
      File.delete(pid_file) if File.exist?(pid_file)
    end

    def port
      @port ||= uri.blank? ? nil : URI.parse(uri).port
    end

    def release_db_connection
      self.update_spid!(nil)
      self.class.release_db_connection
    end
  end
end
