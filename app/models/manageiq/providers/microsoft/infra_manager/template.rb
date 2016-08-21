class ManageIQ::Providers::Microsoft::InfraManager::Template < ManageIQ::Providers::InfraManager::Template

  supports :provisioning do
    if ext_management_system
      if !ext_management_system.supports_provisioning?
        unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning))
      end
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  def proxies4job(_job = nil)
    {
      :proxies => [MiqServer.my_server],
      :message => 'Perform SmartState Analysis on this VM'
    }
  end

  def has_active_proxy?
    true
  end

  def has_proxy?
    true
  end

end
