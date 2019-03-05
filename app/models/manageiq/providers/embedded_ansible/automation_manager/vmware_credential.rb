class ManageIQ::Providers::EmbeddedAnsible::AutomationManager::VmwareCredential < ManageIQ::Providers::EmbeddedAnsible::AutomationManager::CloudCredential
  def self.display_name(number = 1)
    n_('Credential (VMware)', 'Credentials (VMware)', number)
  end
end
