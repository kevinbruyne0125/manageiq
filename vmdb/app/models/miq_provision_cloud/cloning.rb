module MiqProvisionCloud::Cloning
  def find_destination_in_vmdb(ems_ref)
    platform = "Vm" + self.class.name.split("MiqProvision").last
    platform.constantize.where(:ems_id => self.source.ext_management_system.id, :ems_ref => ems_ref).first
  end

  def validate_dest_name
    raise MiqException::MiqProvisionError, "Provision Request's Destination Name cannot be blank" if dest_name.blank?
    raise MiqException::MiqProvisionError, "A VM with name: [#{dest_name}] already exists" if self.source.ext_management_system.vms.where(:name => dest_name).any?
  end

  def prepare_for_clone_task
    validate_dest_name

    clone_options = {
      :key_name          => guest_access_key_pair.try(:name),
      :availability_zone => dest_availability_zone.try(:ems_ref)
    }

    user_data = userdata_payload
    clone_options[:user_data] = user_data unless user_data.blank?

    clone_options
  end

end
