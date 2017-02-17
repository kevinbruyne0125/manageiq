class EmbeddedAnsibleWorker::Runner < MiqWorker::Runner
  def prepare
    Thread.new do
      setup_ansible
      started_worker_record
    end

    self
  end

  # This thread runs forever until a stop request is received, which with send us to do_exit to exit our thread
  def do_work_loop
    Thread.new do
      _log.info("waiting for ansible to start...")
      loop do
        # handle if the ansible setup blew up or timed out
        break if worker.reload.started?
        heartbeat
        send(poll_method)
      end

      update_embedded_ansible_provider

      _log.info("entering ansible monitor loop")
      loop do
        do_work
        send(poll_method)
      end
    end
  end

  def setup_ansible
    _log.info("calling EmbeddedAnsible.configure")
    EmbeddedAnsible.configure unless EmbeddedAnsible.configured?

    _log.info("calling EmbeddedAnsible.start")
    EmbeddedAnsible.start
    _log.info("calling EmbeddedAnsible.start finished")
  end

  def do_work
    if EmbeddedAnsible.alive?
      heartbeat
    else
      EmbeddedAnsible.start unless EmbeddedAnsible.running?
    end
  end

  # Because we're running in a thread on the Server
  # we need to intercept SystemExit and exit our thread,
  # not the main server thread!
  def do_exit(*args)
    # ensure this doesn't fail or that we can still get to the super call
    EmbeddedAnsible.disable
    super
  rescue SystemExit
    _log.info("#{log_prefix} SystemExit received, exiting monitoring Thread")
    Thread.exit
  end

  def update_embedded_ansible_provider
    server   = MiqServer.my_server(true)
    provider = ManageIQ::Providers::EmbeddedAnsible::Provider.first_or_initialize

    provider.name = "Embedded Ansible"
    provider.zone = server.zone
    provider.url  = URI::HTTPS.build(:host => server.hostname || server.ipaddress, :path => "/ansibleapi/v1").to_s

    provider.save!

    admin_auth = MiqDatabase.first.ansible_admin_authentication

    provider.update_authentication(:default => {:userid => admin_auth.userid, :password => admin_auth.password})
  end

  # Base class methods we override since we don't have a separate process.  We might want to make these opt-in features in the base class that this subclass can choose to opt-out.
  def set_process_title; end
  def set_connection_pool_size; end
  def message_sync_active_roles(*_args); end
  def message_sync_config(*_args); end
end
