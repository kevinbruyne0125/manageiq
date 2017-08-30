module CockpitMixin
  extend ActiveSupport::Concern
  def cockpit_server
    ext_management_system.try(:zone).try(:remote_cockpit_ws_miq_server)
  end

  def cockpit_worker
    cockpit_server.nil? ? nil : MiqCockpitWsWorker.fetch_worker_settings_from_server(miq_server)
  end
end
