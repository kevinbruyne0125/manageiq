module Metric::Targets
  cache_with_timeout(:perf_capture_always, 1.minute) do
    MiqRegion.my_region.perf_capture_always
  end

  def self.perf_capture_always=(options)
    perf_capture_always_clear_cache
    MiqRegion.my_region.perf_capture_always = options
  end

  def self.capture_infra_targets(zone, options)
    # Preload all of the objects we are going to be inspecting.
    includes = {:ext_management_systems => {:hosts => {:ems_cluster => :tags, :tags => {}}}}
    includes[:ext_management_systems][:hosts][:storages] = :tags unless options[:exclude_storages]
    includes[:ext_management_systems][:hosts][:vms] = :ext_management_system unless options[:exclude_vms]
    MiqPreloader.preload(zone, includes)
    all_hosts = capture_host_targets(zone)
    targets = hosts = only_enabled(all_hosts)
    targets += capture_storage_targets(all_hosts) unless options[:exclude_storages]
    targets += capture_vm_targets(hosts) unless options[:exclude_vms]

    targets
  end

  def self.only_enabled(targets)
    # If it can and does have a cluster, then ask that, otherwise, ask host itself.
    targets.select do |t|
      t.respond_to?(:ems_cluster) && t.ems_cluster ? t.ems_cluster.perf_capture_enabled? : t.perf_capture_enabled?
    end
  end

  # @return vms under all availability zones
  #         and vms under no availability zone
  # NOTE: some stacks (e.g. nova) default to no availability zone
  def self.capture_cloud_targets(zone, options = {})
    return [] if options[:exclude_vms]

    MiqPreloader.preload(zone.ems_clouds, :vms => [{:availability_zone => :tags}, :ext_management_system])

    zone.ems_clouds.flat_map(&:vms).select do |vm|
      vm.state == 'on' && (vm.availability_zone.nil? || vm.availability_zone.perf_capture_enabled?)
    end
  end

  def self.capture_container_targets(zone, _options)
    includes = {
      :container_nodes  => :tags,
      :container_groups => [:tags, :containers => :tags],
    }

    MiqPreloader.preload(zone.ems_containers, includes)

    targets = []
    zone.ems_containers.each do |ems|
      targets += ems.container_nodes
      targets += ems.container_groups
      targets += ems.container_groups.flat_map(&:containers)
    end

    targets
  end

  def self.capture_host_targets(zone)
    # keeping all_hosts around because capture storage targets runs off of all hosts and
    # not just enabled ones. if that changes, then move the filtering into here.
    zone.ext_management_systems.flat_map(&:hosts)
  end

  # @param [Host] all hosts that have an ems
  # disabled hosts are passed in. this may change in the future
  # @return [Array<Storage>] supported storages
  # hosts preloaded storages and tags
  def self.capture_storage_targets(hosts)
    hosts.flat_map(&:storages).uniq.select { |s| Storage.supports?(s.store_type) & s.perf_capture_enabled? }
  end

  # @param [Host] hosts that are enabled or cluster enabled
  def self.capture_vm_targets(hosts)
    hosts.select(&:perf_capture_enabled?)
         .flat_map { |t| t.vms.select { |v| v.ext_management_system && v.state == 'on' } }
  end

  # If a Cluster, standalone Host, or Storage is not enabled, skip it.
  # If a Cluster is enabled, capture all of its Hosts.
  # If a Host is enabled, capture all of its Vms.
  def self.capture_targets(zone = nil, options = {})
    zone = MiqServer.my_server.zone if zone.nil?
    zone = Zone.find(zone) if zone.kind_of?(Integer)
    capture_infra_targets(zone, options) + \
      capture_cloud_targets(zone, options) + \
      capture_container_targets(zone, options)
  end
end
