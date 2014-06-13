module MiqProvisionVmware::StateMachine
  def create_destination
    signal :determine_placement
  end

  def determine_placement
    host, datastore = self.placement

    self.options[:dest_host] = [host.id, host.name]

    if get_option(:new_datastore_create) == true
      signal :poll_placement_completed
    else
      self.options[:dest_storage] = [datastore.id, datastore.name]
      signal :start_clone_task
    end
  end

  def poll_placement_completed
    ds_name = get_option(:new_datastore_name)
    datastore = dest_host.storages.detect {|s| s.name == ds_name}

    if datastore
      self.options[:dest_storage] = [datastore.id, datastore.name]
      signal :start_clone_task
    else
      $log.info("MIQ(#{self.class.name}#poll_placement_completed) Unable to find Datastore: [#{ds_name}], will retry")
      requeue_phase
    end
  end

  def start_clone_task
    update_and_notify_parent(:message => "Starting Clone of #{clone_direction}")

    # Use this ID to validate the VM when we check in the post-provision method
    self.phase_context[:new_vm_validation_guid] = MiqUUID.new_guid

    clone_options = prepare_for_clone_task
    log_clone_options(clone_options)
    self.phase_context[:clone_task_mor] = start_clone(clone_options)
    signal :poll_clone_complete
  end

  def poll_clone_complete
    clone_status, status_message = do_clone_task_check(self.phase_context[:clone_task_mor])

    status_message = "completed; post provision work queued" if clone_status
    message = "Clone of #{clone_direction} is #{status_message}"
    $log.info("MIQ(#{self.class.name}#poll_clone_complete) #{message}")
    update_and_notify_parent(:message => message)

    if clone_status
      self.phase_context.delete(:clone_task_mor)
      EmsRefresh.queue_refresh(dest_host)
      signal :poll_destination_in_vmdb
    else
      requeue_phase
    end
  end

  def poll_destination_in_vmdb
    update_and_notify_parent(:message => "Validating New #{destination_type}")

    self.destination = find_destination_in_vmdb
    if self.destination
      self.phase_context.delete(:new_vm_validation_guid)
      signal :customize_destination
    else
      $log.info("MIQ(#{self.class.name}#poll_destination_in_vmdb) Unable to find #{destination_type} [#{dest_name}] with validation guid [#{self.phase_context[:new_vm_validation_guid]}], will retry")
      requeue_phase
    end
  end

  def customize_destination
    $log.info("MIQ(#{self.class.name}#customize_destination) Post-processing #{destination_type} id: [#{self.destination.id}], name: [#{dest_name}]")
    update_and_notify_parent(:message => "Starting New #{destination_type} Customization")

    set_cpu_and_memory_allocation(self.destination) if reconfigure_hardware_on_destination?
    signal :autostart_destination
  end

  def autostart_destination
    if get_option(:vm_auto_start)
      message = "Starting"
      $log.info("MIQ(#{self.class.name}#autostart_destination) #{message} #{for_destination}")
      update_and_notify_parent(:message => message)
      start_with_cache_reset
    end

    signal :post_create_destination
  end

  private

  # NOTE: Due to frequent problems with cache not containing the new VM we need to clear the cache and try again.
  def start_with_cache_reset
    self.destination.start
  rescue MiqException::MiqVimResourceNotFound
    $log.info("MIQ(#{self.class.name}#start_with_cache_reset) Unable to start #{for_destination}.  Retrying after VIM cache reset.")
    self.destination.ext_management_system.reset_vim_cache
    self.destination.start
  end

  def clone_direction
    "[#{self.source.name}] to #{destination_type} [#{dest_name}]"
  end

  def for_destination
    "#{destination_type} id: [#{self.destination.id}], name: [#{dest_name}]"
  end

end
