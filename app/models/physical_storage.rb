class PhysicalStorage < ApplicationRecord
  include SupportsFeatureMixin

  belongs_to :ext_management_system, :foreign_key => :ems_id
  belongs_to :physical_rack, :foreign_key => :physical_rack_id
  belongs_to :physical_chassis, :inverse_of => :physical_storages

  has_many :storage_resources, :dependent => :destroy
  belongs_to :physical_storage_family, :inverse_of => :physical_storages

  has_one :asset_detail, :as => :resource, :dependent => :destroy, :inverse_of => false

  has_many :canisters, :dependent => :destroy, :inverse_of => false
  has_many :physical_disks, :dependent => :destroy, :inverse_of => :physical_storage

  has_one :computer_system, :as => :managed_entity, :dependent => :destroy
  has_one :hardware, :through => :computer_system

  has_many :canister_computer_systems, :through => :canisters, :source => :computer_system
  has_many :guest_devices, :through => :hardware

  supports :refresh_ems

  def my_zone
    ems = ext_management_system
    ems ? ems.my_zone : MiqServer.my_zone
  end

  def refresh_ems
    unless ext_management_system
      raise _("No Provider defined")
    end
    unless ext_management_system.has_credentials?
      raise _("No Provider credentials defined")
    end
    unless ext_management_system.authentication_status_ok?
      raise _("Provider failed last authentication check")
    end

    EmsRefresh.queue_refresh(ext_management_system)
  end
end
