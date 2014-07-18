require 'active_support/inflector'
require 'util/miq-exception'

module OpenstackHandle
  class Handle
    attr_accessor :username, :password, :address, :port, :connection_options
    attr_writer   :default_tenant_name

    SERVICE_FALL_BACK = {
      "Network" => "Compute",
      "Image"   => "Compute",
      "Volume"  => "Compute",
      "Storage" => nil
    }

    SERVICE_NAME_MAP = {
      "Compute" => :nova,
      "Network" => :neutron,
      "Image"   => :glance,
      "Volume"  => :cinder,
      "Storage" => :swift
    }

    def self.raw_connect(username, password, auth_url, service = "Compute", extra_opts = nil)
      opts = {
        :provider           => 'OpenStack',
        :openstack_auth_url => auth_url,
        :openstack_username => username,
        :openstack_api_key  => password,
      }
      opts.merge!(extra_opts) if extra_opts

      Fog.const_get(service).new(opts)
    rescue Fog::Errors::NotFound => err
      raise MiqException::ServiceNotAvailable if err.message.include?("Could not find service")
      raise
    end

    def self.auth_url(address, port = 5000)
      "http://#{address}:#{port}/v2.0/tokens"
    end

    def self.connection_options=(hash)
      @connection_options = hash
    end

    def self.connection_options
      @connection_options
    end

    def initialize(username, password, address, port = nil)
      @username = username
      @password = password
      @address  = address
      @port     = port || 5000

      @service_names      = {}
      @connection_cache   = {}
      @connection_options = self.class.connection_options
    end

    def auth_url
      self.class.auth_url(address, port)
    end

    def browser_url
      "http://#{address}/dashboard"
    end

    def connect(options = {})
      opts = options.dup
      service  = (opts.delete(:service) || "Compute").to_s.camelize
      if (tenant = opts.delete(:tenant_name))
        opts[:openstack_tenant] = tenant
      end
      auth_url = self.class.auth_url(address, port)
      opts[:connection_options] = connection_options if connection_options

      svc = self.class.raw_connect(username, password, auth_url, service, opts)
      OpenstackHandle.const_get("#{service}Delegate").new(svc, self)
    end

    def compute_service(tenant_name = nil)
      connect_cache("Compute", tenant_name)
    end
    alias_method :connect_compute, :compute_service

    def identity_service
      @identity_service ||= connect(:service => "Identity")
    end
    alias_method :connect_identity, :identity_service

    def network_service(tenant_name = nil)
      connect_cache("Network", tenant_name)
    end
    alias_method :connect_network, :network_service

    def detect_network_service(tenant_name = nil)
      detect_service("Network", tenant_name)
    end

    def network_service_name
      service_name("Network")
    end

    def image_service(tenant_name = nil)
      connect_cache("Image", tenant_name)
    end
    alias_method :connect_image, :image_service

    def detect_image_service(tenant_name = nil)
      detect_service("Image", tenant_name)
    end

    def image_service_name
      service_name("Image")
    end

    def volume_service(tenant_name = nil)
      connect_cache("Volume", tenant_name)
    end
    alias_method :connect_volume, :volume_service

    def detect_volume_service(tenant_name = nil)
      detect_service("Volume", tenant_name)
    end

    def volume_service_name
      service_name("Volume")
    end

    def storage_service(tenant_name = nil)
      connect_cache("Storage", tenant_name)
    end
    alias_method :connect_storage, :storage_service

    def detect_storage_service(tenant_name = nil)
      detect_service("Storage", tenant_name)
    end

    def storage_service_name
      service_name("Storage")
    end

    def detect_service(service, tenant_name = nil)
      svc = connect_cache(service, tenant_name)
      @service_names[service] = SERVICE_NAME_MAP[service]
      svc
    rescue MiqException::ServiceNotAvailable
      unless (fbs = SERVICE_FALL_BACK[service])
        @service_names[service] = :none
        return nil
      end
      svc = connect_cache(fbs, tenant_name)
      @service_names[service] = SERVICE_NAME_MAP[fbs]
      svc
    end

    def service_name(service)
      return @service_names[service] if @service_names[service]
      detect_service(service)
      @service_names[service]
    end

    def tenants
      @tenants ||= identity_service.tenants
    end

    def tenant_names
      @tenant_names ||= tenants.collect { |t| t.name }
    end

    def accessible_tenants
      @accessible_tenants ||= tenants.select do |t|
        begin
          compute_service(t.name)
          true
        rescue # Excon::Errors::Unauthorized
          false
        end
      end
    end

    def accessible_tenant_names
      @accessible_tenant_names ||= accessible_tenants.collect { |t| t.name }
    end

    def default_tenant_name
      @default_tenant_name ||= accessible_tenant_names.detect { |tn| tn != "services" }
    end

    def service_for_each_accessible_tenant(service, &block)
      if block.arity == 1
        accessible_tenant_names.each { |t| block.call(detect_service(service, t)) }
      elsif block.arity == 2
        accessible_tenants.each { |t| block.call(detect_service(service, t.name), t) }
      else
        raise "OpenstackHandle#service_for_each_accessible_tenant: unexpected number of block args: #{block.arity}"
      end
    end

    def accessor_for_accessable_tenants(service, accessor, uniq_id)
      ra = []
      service_for_each_accessible_tenant(service) do |svc|
        ra.concat(svc.send(accessor).to_a)
      end
      ra.uniq { |i| i.send(uniq_id) }
    end

    private

    def connect_cache(service, tenant_name)
      tenant_name ||= default_tenant_name
      svc_cache = (@connection_cache[service] ||= {})
      svc_cache[tenant_name] ||= connect(:service => service, :tenant_name => tenant_name)
    end
  end
end
