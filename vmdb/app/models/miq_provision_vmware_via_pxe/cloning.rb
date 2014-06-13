module MiqProvisionVmwareViaPxe::Cloning
  def build_config_disk_spec(vmcs)
    log_header = "MIQ(#{self.class.name}.build_config_disk_spec)"
    get_disks.each do |disk|
      self.remove_disk(vmcs, disk)
      new_disk = copy_disk_details(disk)
      self.add_disk(vmcs, new_disk, {"key" => new_disk[:bus]}, get_next_device_idx)
    end

    super
  end

  def get_disks
    inventory_hash = self.source.with_provider_connection do |vim|
      vim.virtualMachineByMor(self.source.ems_ref_obj)
    end

    devs = inventory_hash.fetch_path("config", "hardware", "device") || []
    devs.select { |d| d.xsiType == "VirtualDisk" }.sort_by { |d| d["key"].to_i }
  end

  def remove_disk(vmcs, disk)
    log_header = "MIQ(#{self.class.name}.remove_disk)"
    add_device_config_spec(vmcs, VirtualDeviceConfigSpecOperation::Remove) do |vdcs|
      $log.info "#{log_header} Deleting disk device with Device Name:<#{disk.fetch_path('deviceInfo','label')}>"
      vdcs.device = disk
    end
  end

  def copy_disk_details(vim_disk)
    {
      :bus         => vim_disk["controllerKey"],
      :pos         => vim_disk["unitNumber"],
      :sizeInMB    => vim_disk["capacityInKB"].to_i / 1024,
      :label       => vim_disk.fetch_path("deviceInfo", "label"),
      :summary     => vim_disk.fetch_path("deviceInfo", "summary"),
      :connectable => {
        :allowguestcontrol => vim_disk.fetch_path("connectable", "allowGuestControl"),
        :startconnected    => vim_disk.fetch_path("connectable", "startConnected"),
        :connected         => vim_disk.fetch_path("connectable", "connected"),
      },
      :backing     => {
        :diskmode        => vim_disk.fetch_path("backing", "diskMode"),
        :split           => vim_disk.fetch_path("backing", "split"),
        :thinprovisioned => vim_disk.fetch_path("backing", "thinProvisioned"),
        :writethrough    => vim_disk.fetch_path("backing", "writeThrough"),
      }
    }
  end

  def build_customization_spec
    nil
  end
end
