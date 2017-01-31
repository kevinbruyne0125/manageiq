class ManageIQ::Providers::Openstack::NetworkManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  include ManageIQ::Providers::Openstack::EventCatcherMixin

  def add_openstack_queue(event)
    event_hash = ManageIQ::Providers::Openstack::NetworkManager::EventParser.event_to_hash(event, :ems_id)
    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end
end
