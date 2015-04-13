class ContainerNode < ActiveRecord::Base
  include ReportableMixin
  # :name, :uid, :creation_timestamp, :resource_version
  belongs_to :ext_management_system, :foreign_key => "ems_id"
  has_many   :container_groups
  belongs_to :lives_on, :polymorphic => true
end
