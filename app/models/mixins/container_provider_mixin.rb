module ContainerProviderMixin
  extend ActiveSupport::Concern

  included do
    has_many :container_nodes, :foreign_key => :ems_id, :dependent => :destroy
    has_many :container_groups, :foreign_key => :ems_id, :dependent => :destroy
    has_many :container_services, :foreign_key => :ems_id, :dependent => :destroy
    has_many :container_replicators, :foreign_key => :ems_id, :dependent => :destroy
    has_many :containers, :through => :container_groups

    # TODO: support real authentication using certificates
    before_validation :ensure_authentications_record
  end

  module ClassMethods
    def raw_api_endpoint(hostname, port)
      URI::HTTPS.build(:host => hostname, :port => port.presence.try(:to_i))
    end

    def kubernetes_connect(hostname, port, options)
      require 'kubeclient'
      api_endpoint = raw_api_endpoint(hostname, port)
      kubeclient = Kubeclient::Client.new(api_endpoint, kubernetes_version)
      # TODO: support real authentication using certificates
      kubeclient.ssl_options(:verify_ssl => OpenSSL::SSL::VERIFY_NONE)
      kubeclient.basic_auth(options[:username], options[:password]) if options[:username] && options[:password]
      kubeclient.bearer_token(options[:bearer]) if options[:bearer]
      kubeclient
    end

    def kubernetes_version
      'v1beta3'
    end
  end

  # UI methods for determining availability of fields
  def supports_port?
    true
  end

  def api_endpoint
    self.class.raw_api_endpoint(hostname, port)
  end

  def connect(options = {})
    options[:hostname] ||= address
    options[:port] ||= self.port
    options[:user] ||= authentication_userid(options[:auth_type])
    options[:pass] ||= authentication_password(options[:auth_type])
    options[:bearer] ||= authentication_token(options[:auth_type])
    self.class.raw_connect(options[:hostname], options[:port], options)
  end

  def verify_credentials(auth_type = nil, options = {})
    options = options.merge(:auth_type => auth_type)

    with_provider_connection(options, &:api_valid?)
    rescue SocketError,
           Errno::ECONNREFUSED,
           RestClient::ResourceNotFound,
           RestClient::InternalServerError => err
      raise MiqException::MiqUnreachableError, err.message, err.backtrace
    rescue RestClient::Unauthorized   => err
      raise MiqException::MiqInvalidCredentialsError, err.message, err.backtrace
  end

  def ensure_authentications_record
    # TODO: support real authentication using certificates
    return if authentications.present?
    update_authentication(:default => {:userid => "_", :save => false})
  end

  # required by aggregate_hardware
  def all_computer_system_ids
    MiqPreloader.preload(container_nodes, :computer_system)
    container_nodes.collect { |n| n.computer_system.id }
  end

  def aggregate_logical_cpus(targets = nil)
    aggregate_hardware(:computer_systems, :logical_cpus, targets)
  end

  def aggregate_memory(targets = nil)
    aggregate_hardware(:computer_systems, :memory_cpu, targets)
  end
end
