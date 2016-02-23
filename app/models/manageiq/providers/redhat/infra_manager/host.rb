class ManageIQ::Providers::Redhat::InfraManager::Host < ::Host
  def provider_object(connection = nil)
    connection ||= ext_management_system.connect
    connection.get_resource_by_ems_ref(ems_ref)
  end

  def validate_scan_and_check_compliance_queue
    validate_unsupported("Scan and Check Compilance Queue")
  end

  def validate_check_compliance_queue
    validate_unsupported("Check Compilance Queue")
  end

  def verify_credentials(auth_type = nil, options = {})
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(auth_type)
    if auth_type.to_s != 'ipmi' && os_image_name !~ /linux_*/
      raise MiqException::MiqHostError, "Logon to platform [#{os_image_name}] not supported"
    end
    case auth_type.to_s
    when 'ipmi' then verify_credentials_with_ipmi(auth_type)
    else
      verify_credentials_with_ssh(auth_type, options)
    end

    true
  end
end
