module ManageIQ::Providers::Vmware::InfraManager::Provision::Placement
  extend ActiveSupport::Concern

  protected

  def placement
    if get_option(:placement_auto) == true
      automatic_placement
    else
      manual_placement
    end
  end

  private

  def manual_placement
    _log.info("Manual placement...")
    return selected_placement_obj(:placement_host_name, Host),
           selected_placement_obj(:placement_cluster_name, EmsCluster),
           selected_placement_obj(:placement_ds_name, Storage)
  end

  def automatic_placement
    # get most suitable host and datastore for new VM
    _log.info("Getting most suitable host and datastore for new VM from automate...")
    host, datastore = get_most_suitable_host_and_storage
    cluster = host.ems_cluster

    _log.info("Host Name: [#{host.name}] Id: [#{host.id}]") if host
    _log.info("Cluster Name: [#{cluster.name}] Id: [#{cluster.id}]") if cluster
    _log.info("Datastore Name: [#{datastore.name}] ID : [#{datastore.id}]") if datastore
    host ||= selected_placement_obj(:placement_host_name, Host)
    cluster ||= selected_placement_obj(:placement_cluster_name, EmsCluster)
    datastore ||= selected_placement_obj(:placement_ds_name, Storage)
    return host, cluster, datastore
  end

  def selected_placement_obj(key, klass)
    klass.find_by(:id => get_option(key)).tap do |obj|
      #TODO raise MiqException::MiqProvisionError, "Destination #{key} not provided" unless obj
      _log.info("Using selected #{key} : [#{obj.name}] id : [#{obj.id}]") if obj
    end
  end
end
