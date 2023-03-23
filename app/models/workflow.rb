class Workflow < ApplicationRecord
  include NewWithTypeStiMixin
  include TenancyMixin

  belongs_to :ext_management_system, :inverse_of => :workflows, :class_name => "ManageIQ::Providers::AutomationManager", :foreign_key => :ems_id
  belongs_to :tenant

  has_many :workflow_instances, :dependent => :destroy

  # For now this is a convenience method for creating these
  # during development.
  # In the future these will be imported from a git repository
  # or authored by users via our UI.
  def self.create_from_json!(json)
    json = JSON.parse(json) if json.kind_of?(String)
    name = json["Comment"]

    create!(:ext_management_system => ManageIQ::Providers::Workflows::AutomationManager.first, :name => name, :workflow_content => json)
  end
end
