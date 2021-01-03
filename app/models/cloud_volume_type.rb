class CloudVolumeType < ApplicationRecord
  # CloudVolumeTypes represent various "flavors" of
  # volume that are available to create within a given
  # Storage service.
  include NewWithTypeStiMixin
  include ProviderObjectMixin

  acts_as_miq_taggable

  belongs_to :ext_management_system, :foreign_key => :ems_id, :class_name => "ExtManagementSystem"

  def self.class_by_ems(ext_management_system)
    ext_management_system && ext_management_system.class::CloudVolumeType
  end

  def self.display_name(number = 1)
    n_('Cloud Volume Type', 'Cloud Volume Types', number)
  end
end
