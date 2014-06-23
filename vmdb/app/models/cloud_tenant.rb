class CloudTenant < ActiveRecord::Base
  attr_accessible :description, :ems_ref, :enabled, :name

  belongs_to      :ext_management_system, :foreign_key => "ems_id"
  has_many        :security_groups
  has_many        :cloud_networks
  has_many        :vms_and_templates
  has_many        :floating_ips
  has_many        :cloud_volumes
  has_many        :cloud_volume_snapshots
  has_many        :cloud_object_store_containers
  has_many        :cloud_object_store_objects
  has_many        :cloud_resource_quotas
end
