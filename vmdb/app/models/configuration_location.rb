class ConfigurationLocation < ActiveRecord::Base
  belongs_to :provisioning_manager
  belongs_to :parent, :class_name => 'ConfigurationLocation'
  has_and_belongs_to_many :configuration_profiles

  alias_attribute :display_name, :title

  def path
    (parent.try(:path) || []).push(self)
  end
end
