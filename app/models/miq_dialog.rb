class MiqDialog < ApplicationRecord
  include_concern "Seeding"

  validates :name, :description, :presence => true
  validates :name, :unique_within_region => { :scope => :dialog_type, :match_case => false }

  scope :with_dialog_type, ->(dialog_type) { where(:dialog_type => dialog_type) }

  DIALOG_TYPES = [
    [_("VM Provision"),                "MiqProvisionWorkflow"],
    [_("Configured System Provision"), "MiqProvisionConfiguredSystemWorkflow"],
    [_("VM Migrate"),                  "VmMigrateWorkflow"],
    [_("Physical Server Provision"),   "PhysicalServerProvisionWorkflow"]
  ].freeze

  serialize :content

  def self.display_name(number = 1)
    n_('Dialog', 'Dialogs', number)
  end
end
