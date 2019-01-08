# This server allows the user to access remote endpoints through an HTTP(S)
# connection to the appliance. Opposed to a direct access or a forwarded port
# it is not necessary to expose an extra IP:port combination to the client.
#
# It uses socket hijacking to retrieve the underlying TCP socket connection
# of the HTTP request incoming from a client. This socket is detached from
# the Rack middleware and handled by a separate transmitter thread.
# The remote address of the console is determined by a one time secret that
# is part of the URL and it points to a SystemConsole record in the database.
#
# On the lowest level the transmitter thread operates with regular sockets,
# however, both on the client and server side wrappers are used to translate
# between a pair of sockets. Due to some limitations in the websocket driver
# gem, the reading/writing operations are defined in the fetch/issue methods.
#
# The selector for the sockets is provided by an external gem and it handles
# the dependency between the socket pairs, i.e. one should be ready to read
# while other one should be ready to write at the same time. The pairs ready
# for transmission are handled by the `each_ready` iterator. As the iterator
# always returns with a socket to read and a socket to write, the `@adapters`
# hash has been used to access the corresponding wrappers.

class WebsocketServer
  attr_accessor :logger

  RACK_404 = [404, {'Content-Type' => 'text/plain'}, ['Not found']].freeze
  RACK_YAY = [-1, {}, []].freeze

  def initialize(options = {})
    @logger = options.fetch(:logger, $remote_console_log)
    @logger.info('Initializing websocket server!')
    @proxy = SurroGate.new(logger)
    @adapters = {}

    @transmitter = Thread.new do
      loop do
        @proxy.select(1000)

        @proxy.each_ready do |left, right|
          begin
            @adapters[left].fetch(64.kilobytes) { |data| @adapters[right].issue(data) } # left -> right
          rescue IOError
            cleanup(:info, "Closing websocket proxy for VM %{vm_id}", left, right)
          rescue StandardError => ex
            cleanup(:error, "Websocket proxy for VM %{vm_id} errored with #{ex} #{ex.backtrace.join("\n")}", left, right)
          end
        end
      end
    end

    @transmitter.abort_on_exception = true
  end

  def call(env)
    exp = %r{^/ws/console/([a-zA-Z0-9]+)/?$}.match(env['REQUEST_URI'])
    if WebSocket::Driver.websocket?(env) && same_origin_as_host?(env) && exp.present?
      @logger.info("Remote console connection initiated with secret #{exp[1]}")
      init_proxy(env, exp[1])
    else
      @logger.error('Invalid websocket request or URL')
      RACK_404
    end
  end

  def healthy?
    %w(run sleep).include?(@transmitter.status)
  end

  private

  def init_proxy(env, secret)
    record = SystemConsole.find_by!(:url_secret => secret)

    begin
      ws_sock = env['rack.hijack'].call
      console_sock = TCPSocket.open(record.host_name, record.port)

      @adapters[console_sock] = RemoteConsole.new(record, console_sock)
      @adapters[ws_sock] = WebsocketAdapter.new(record, env, ws_sock)

      @proxy.push(ws_sock, console_sock)
    rescue StandardError => ex
      cleanup(:error, "Websocket proxy for VM %{vm_id} errored with #{ex} #{ex.backtrace.join("\n")}", console_sock, ws_sock, record)
      RACK_404
    else
      @logger.info("Starting websocket proxy for VM #{record.vm_id}")
      RACK_YAY # Rack needs this as a return value
    ensure
      # Release the connection because one SPICE console can open multiple TCP connections
      ActiveRecord::Base.connection_pool.release_connection
    end
  end

  def cleanup(log_level, message, sock_a, sock_b, record = nil)
    record ||= @adapters.values_at(sock_a, sock_b).map { |a| a.try(:record) }.find(&:itself)

    if record
      record.destroy_or_mark
      @logger.send(log_level, message % {:vm_id => record.vm_id})
    end

    [sock_a, sock_b].each do |sock|
      sock.try(:close)
      @adapters.delete(sock)
    end

    @proxy.pop(sock_a, sock_b) unless sock_a.nil? || sock_b.nil?
  end

  # Primitive same-origin policy checking in production
  def same_origin_as_host?(env)
    proto = Rack::Request.new(env).ssl? ? 'https' : 'http'
    host = env['HTTP_X_FORWARDED_HOST'] ? env['HTTP_X_FORWARDED_HOST'].split(/,\s*/).first : env['HTTP_HOST']
    Rails.env.development? || env['HTTP_ORIGIN'] == "#{proto}://#{host}"
  end
end
