module ManageIQ::Providers::AnsibleTower::Shared::AutomationManager::ConfigurationScriptSource
  extend ActiveSupport::Concern

  include ProviderObjectMixin

  module ClassMethods
    def provider_collection(manager)
      manager.with_provider_connection do |connection|
        connection.api.projects
      end
    end
  end

  def provider_object(connection = nil)
    (connection || connection_source.connect).api.projects.find(manager_ref)
  end

  REFRESH_ON_TOWER_SLEEP = 1.second
  def refresh_in_provider
    with_provider_object do |project|
      return unless project.can_update?

      project_update = project.update

      while project_update.finished.blank?
        sleep REFRESH_ON_TOWER_SLEEP
        project_update = project_update.api.project_updates.find(project_update.id)
      end
    end
  end
end
