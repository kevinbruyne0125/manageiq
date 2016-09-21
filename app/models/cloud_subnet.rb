class CloudSubnet < ApplicationRecord
  include_concern 'Operations'

  include NewWithTypeStiMixin
  include ProviderObjectMixin
  include AsyncDeleteMixin
  include VirtualTotalMixin

  acts_as_miq_taggable

  belongs_to :ext_management_system, :foreign_key => :ems_id, :class_name => "ManageIQ::Providers::NetworkManager"
  belongs_to :cloud_network
  belongs_to :cloud_tenant
  belongs_to :availability_zone
  belongs_to :network_group
  belongs_to :network_router
  belongs_to :parent_cloud_subnet, :class_name => "::CloudSubnet"

  has_many :cloud_subnet_network_ports, :dependent => :destroy
  has_many :network_ports, :through => :cloud_subnet_network_ports, :dependent => :destroy
  has_many :vms, :through => :network_ports, :source => :device, :source_type => 'VmOrTemplate'
  has_many :cloud_subnets, :foreign_key => :parent_cloud_subnet_id

  has_one :public_network, :through => :network_router, :source => :cloud_network

  # Use for virtual columns, mainly for modeling array and hash types, we get from the API
  serialize :extra_attributes
  serialize :dns_nameservers

  virtual_column :allocation_pools, :type => :string
  virtual_column :host_routes,      :type => :string
  virtual_column :ip_version,       :type => :string
  virtual_column :subnetpool_id,    :type => :string

  # Define all getters and setters for extra_attributes related virtual columns
  %i(allocation_pools host_routes ip_version subnetpool_id).each do |action|
    define_method("#{action}=") do |value|
      extra_attributes_save(action, value)
    end

    define_method(action) do
      extra_attributes_load(action)
    end
  end

  def dns_nameservers_show
    dns_nameservers.join(", ") if dns_nameservers
  end
  virtual_column :dns_nameservers_show, :type => :string, :uses => :dns_nameservers

  virtual_total :total_vms, :vms, :uses => :vms

  def self.class_by_ems(ext_management_system)
    # TODO: use a factory on ExtManagementSystem side to return correct class for each provider
    ext_management_system && ext_management_system.class::CloudSubnet
  end

  def self.create_subnet(ext_management_system, options = {})
    raise ArgumentError, _("ext_management_system cannot be nil") if ext_management_system.nil?

    klass = class_by_ems(ext_management_system)
    klass.raw_create_subnet(ext_management_system, options)
  end

  def self.validate_create_subnet(ext_management_system)
    klass = class_by_ems(ext_management_system)
    return klass.validate_create_subnet(ext_management_system) if ext_management_system &&
                                                                  klass.respond_to?(:validate_create_subnet)
    validate_unsupported("Create Subnet Operation")
  end

  def delete_subnet
    raw_delete_subnet
  end

  def validate_delete_subnet
    validate_unsupported("Delete Subnet Operation")
  end

  def raw_delete_subnet
    raise NotImplementedError, _("raw_delete_subnet must be implemented in a subclass")
  end

  def raw_update_subnet(_options = {})
    raise NotImplementedError, _("raw_update_subnet must be implemented in a subclass")
  end

  def update_subnet(options = {})
    raw_update_subnet(options) unless options.empty?
  end

  private

  def extra_attributes_save(key, value)
    self.extra_attributes = {} if extra_attributes.blank?
    self.extra_attributes[key] = value
  end

  def extra_attributes_load(key)
    self.extra_attributes[key] unless extra_attributes.blank?
  end
end
