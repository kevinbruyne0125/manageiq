module ManageIQ::Providers
  class PhysicalInfraManager < BaseManager
    include SupportsFeatureMixin

    has_many :physical_chassis,  :foreign_key => "ems_id", :dependent => :destroy, :inverse_of => :ext_management_system
    has_many :physical_racks,    :foreign_key => "ems_id", :dependent => :destroy, :inverse_of => :ext_management_system
    has_many :physical_servers,  :foreign_key => "ems_id", :dependent => :destroy, :inverse_of => :ext_management_system
    has_many :physical_switches, :foreign_key => "ems_id", :dependent => :destroy, :inverse_of => :ext_management_system
    has_many :physical_storages, :foreign_key => "ems_id", :dependent => :destroy, :inverse_of => :ext_management_system

    virtual_total :total_physical_chassis,  :physical_chassis
    virtual_total :total_physical_racks,    :physical_racks
    virtual_total :total_physical_servers,  :physical_servers
    virtual_total :total_physical_switches, :physical_switches
    virtual_total :total_physical_storages, :physical_storages

    virtual_column :total_hosts, :type => :integer
    virtual_column :total_vms,   :type => :integer

    virtual_column :total_valid, :type => :integer
    virtual_column :total_warning, :type => :integer
    virtual_column :total_critical, :type => :integer
    virtual_column :health_state_info, :type => :json

    virtual_column :total_racks, :type => :integer
    virtual_column :total_resources, :type => :integer
    virtual_column :resources_info, :type => :json

    class << model_name
      define_method(:route_key) { "ems_physical_infras" }
      define_method(:singular_route_key) { "ems_physical_infra" }
    end

    def self.ems_type
      @ems_type ||= "physical_infra_manager".freeze
    end

    def self.description
      @description ||= "PhysicalInfraManager".freeze
    end

    def validate_authentication_status
      {:available => true, :message => nil}
    end

    def count_health_state(state)
      count = 0
      count += physical_chassis.where(:health_state => state).count
      count += physical_servers.where(:health_state => state).count
      count += physical_switches.where(:health_state => state).count
      count += physical_storages.where(:health_state => state).count
    end

    def assign_health_states
      {
        :total_valid    => count_health_state("Valid"),
        :total_warning  => count_health_state("Warning"),
        :total_critical => count_health_state("Critical"),
      }
    end

    alias health_state_info assign_health_states

    def count_resources(component = nil)
      count = 0

      if component
        count = component.count
      else
        count += physical_racks.count
        count += physical_chassis.count
        count += physical_servers.count
        count += physical_switches.count
        count += physical_storages.count
      end
    end

    def assign_resources_info
      {
        :total_racks     => count_resources(physical_racks),
        :total_resources => count_resources,
      }
    end

    alias resources_info assign_resources_info

    def count_physical_servers_with_host
      physical_servers.inject(0) { |t, physical_server| physical_server.host.nil? ? t : t + 1 }
    end

    alias total_hosts count_physical_servers_with_host

    def count_vms
      physical_servers.inject(0) { |t, physical_server| physical_server.host.nil? ? t : t + physical_server.host.vms.size }
    end

    alias total_vms count_vms

    supports :console do
      unless console_supported?
        unsupported_reason_add(:console, N_("Console not supported"))
      end
    end

    def console_supported?
      false
    end

    def console_url
      raise MiqException::Error, _("Console not supported")
    end

    def self.firmware_update_class
      self::FirmwareUpdateTask
    end

    def self.display_name(number = 1)
      n_('Physical Infrastructure Manager', 'Physical Infrastructure Managers', number)
    end
  end
end
