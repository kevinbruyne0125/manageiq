module VmRedhat::Operations::Power
  def validate_pause
    validate_unsupported("Pause Operation")
  end

  def raw_start
    with_provider_object { |rhevm_vm| rhevm_vm.start }
  rescue Ovirt::VmAlreadyRunning
  end

  def raw_stop
    with_provider_object { |rhevm_vm| rhevm_vm.stop }
  rescue Ovirt::VmIsNotRunning
  end

  def raw_suspend
    with_provider_object { |rhevm_vm| rhevm_vm.suspend }
  end
end
