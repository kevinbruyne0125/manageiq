class ManageIQ::Providers::AnsibleTower::Inventory::Target::AutomationManager < ManagerRefresh::Inventory::Target
  def inventory_groups
    collections[:inventory_groups] ||= ManagerRefresh::InventoryCollection.new(
      :model_class    => ManageIQ::Providers::AutomationManager::InventoryRootGroup,
      :association    => :inventory_root_groups,
      :parent         => @root,
      :builder_params => {:manager => @root}
    )
  end

  def configured_systems
    collections[:configured_systems] ||= ManagerRefresh::InventoryCollection.new(
      :model_class    => ManageIQ::Providers::AnsibleTower::AutomationManager::ConfiguredSystem,
      :association    => :configured_systems,
      :parent         => @root,
      :manager_ref    => [:manager_ref],
      :builder_params => {:manager => @root}
    )
  end

  def configuration_scripts
    collections[:configuration_scripts] ||= ManagerRefresh::InventoryCollection.new(
      :model_class    => ManageIQ::Providers::AnsibleTower::AutomationManager::ConfigurationScript,
      :association    => :configuration_scripts,
      :parent         => @root,
      :manager_ref    => [:manager_ref],
      :builder_params => {:manager => @root}
    )
  end

  def configuration_script_sources
    collections[:configuration_script_sources] ||= ManagerRefresh::InventoryCollection.new(
      :model_class    => ConfigurationScriptSource,
      :association    => :configuration_script_sources,
      :manager_ref    => [:manager_ref],
      :parent         => @root,
      :builder_params => {:manager => @root}
    )
  end

  def playbooks
    collections[:playbooks] ||= ManagerRefresh::InventoryCollection.new(
      :model_class    => ManageIQ::Providers::AnsibleTower::AutomationManager::Playbook,
      :association    => :configuration_script_payloads,
      :manager_ref    => [:manager_ref],
      :parent         => @root,
      :builder_params => {:manager => @root}
    )
  end

  def authentication_configuration_script_bases
    collections[:authentication_configuration_script_bases] ||= ManagerRefresh::InventoryCollection.new(
      :model_class => AuthenticationConfigurationScriptBase,
      :association => :authentication_configuration_script_bases,
      :manager_ref => [:authentication, :configuration_script_base],
      :parent      => @root,
    )
  end

  def configuration_script_authentications
    collections[:configuration_script_authentications] ||= ManagerRefresh::InventoryCollection.new(
      :model_class => ManageIQ::Providers::AutomationManager::Authentication,
      :association => :configuration_script_authentications,
      :manager_ref => [:manager_ref],
      :parent      => @root,
    )
  end
end
