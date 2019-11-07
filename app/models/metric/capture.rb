module Metric::Capture
  VALID_CAPTURE_INTERVALS = ['realtime', 'hourly', 'historical'].freeze

  # This is nominally a VMware-specific value, but we currently expect
  # all providers to conform to it.
  REALTIME_METRICS_PER_MINUTE = 3

  REALTIME_PRIORITY = HOURLY_PRIORITY = DAILY_PRIORITY = MiqQueue::NORMAL_PRIORITY
  HISTORICAL_PRIORITY = MiqQueue::LOW_PRIORITY

  # @param [String[ capture interval
  # @return [Integer] MiqQueue priority level for this message
  def self.interval_priority(interval)
    interval == "historical" ? MiqQueue::LOW_PRIORITY : MiqQueue::NORMAL_PRIORITY
  end

  def self.capture_cols
    @capture_cols ||= Metric.columns_hash.collect { |c, h| c.to_sym if h.type == :float && c[0, 7] != "derived" }.compact
  end

  def self.historical_days
    Settings.performance.history.initial_capture_days.to_i
  end

  def self.historical_start_time
    historical_days.days.ago.utc.beginning_of_day
  end

  def self.concurrent_requests(interval_name)
    requests = ::Settings.performance.concurrent_requests[interval_name]
    requests = 20 if requests < 20 && interval_name == 'realtime'
    requests
  end

  def self.standard_capture_threshold(target)
    target_key = target.class.base_model.to_s.underscore.to_sym
    minutes_ago(::Settings.performance.capture_threshold[target_key] ||
                ::Settings.performance.capture_threshold.default)
  end

  def self.alert_capture_threshold(target)
    target_key = target.class.base_model.to_s.underscore.to_sym
    minutes_ago(::Settings.performance.capture_threshold_with_alerts[target_key] ||
                ::Settings.performance.capture_threshold_with_alerts.default)
  end

  def self.perf_capture_timer(ems_id)
    _log.info("Queueing performance capture...")

    ems = ExtManagementSystem.find(ems_id)
    zone = ems.zone
    perf_capture_health_check(zone)
    targets = Metric::Targets.capture_ems_targets(ems)

    targets_by_rollup_parent = calc_targets_by_rollup_parent(targets)
    target_options = calc_target_options(zone, targets_by_rollup_parent)
    targets = filter_perf_capture_now(targets, target_options)
    queue_captures(targets, target_options)

    # Purge tasks older than 4 hours
    MiqTask.delete_older(4.hours.ago.utc, "name LIKE 'Performance rollup for %'")

    _log.info("Queueing performance capture...Complete")
  end

  def self.perf_capture_gap(start_time, end_time, zone_id = nil, ems_id = nil)
    raise ArgumentError, "end_time and start_time must be specified" if start_time.nil? || end_time.nil?
    raise _("Start time must be earlier than End time") if start_time > end_time

    _log.info("Queueing performance capture for range: [#{start_time} - #{end_time}]...")

    emses = if ems_id
              [ExtManagementSystem.find(ems_id)]
            elsif zone_id
              Zone.find(zone_id).ems_metrics_collectable
            else
              MiqServer.my_server.zone.ems_metrics_collectable
            end
    emses.each do |ems|
      targets = Metric::Targets.capture_ems_targets(ems, :exclude_storages => true)
      target_options = Hash.new { |_n, _v| {:start_time => start_time.utc, :end_time => end_time.utc, :zone => ems.zone, :interval => 'historical'} }
      queue_captures(targets, target_options)
    end

    _log.info("Queueing performance capture for range: [#{start_time} - #{end_time}]...Complete")
  end

  # called by the UI
  # @param zone [Zone] zone where the ems resides
  # @param ems [ExtManagementSystem] ems to capture collect
  #
  # pass at least one of these, since we need to specify which ems needs a gap to run
  # Prefer to use the ems over the zone for perf_capture_gap
  def self.perf_capture_gap_queue(start_time, end_time, zone, ems = nil)
    zone ||= ems.zone

    MiqQueue.put(
      :class_name  => name,
      :method_name => "perf_capture_gap",
      :role        => "ems_metrics_coordinator",
      :priority    => MiqQueue::HIGH_PRIORITY,
      :zone        => zone.name,
      :args        => [start_time, end_time, zone.id, ems&.id]
    )
  end

  def self.filter_perf_capture_now(targets, target_options)
    targets.select do |target|
      options = target_options[target]
      # [:force] is set if we already determined this target needs perf capture
      if options[:force] || perf_capture_now?(target)
        true
      else
        _log.debug do
          "Skipping capture of #{target.log_target} -" +
            "Performance last captured on [#{target.last_perf_capture_on}] is within threshold"
        end
        false
      end
    end
  end

  # if it has not been run, or it was a very long time ago, just run it
  # if it has been run very recently (even too recently for realtime) then skip it
  # otherwise, it needs to be run if it is realtime, but not if it is standard threshold
  # assumes alert capture threshold <= standard capture threshold
  def self.perf_capture_now?(target)
    return true  if target.last_perf_capture_on.nil?
    return true  if target.last_perf_capture_on < standard_capture_threshold(target)
    return false if target.last_perf_capture_on >= alert_capture_threshold(target)
    MiqAlert.target_needs_realtime_capture?(target)
  end

  #
  # Capture entry points
  #

  def self.perf_capture_health_check(zone)
    q_items = MiqQueue.select(:method_name, :created_on).order(:created_on)
              .where(:state       => "ready",
                     :role        => "ems_metrics_collector",
                     :method_name => %w(perf_capture perf_capture_realtime perf_capture_hourly perf_capture_historical),
                     :zone        => zone.name)
    items_by_interval = q_items.group_by(&:method_name)
    items_by_interval.reverse_merge!("perf_capture_realtime" => [], "perf_capture_hourly" => [], "perf_capture_historical" => [])
    items_by_interval.each do |method_name, items|
      interval = method_name.sub("perf_capture_", "")
      msg = "#{items.length} #{interval.inspect} captures on the queue for zone [#{zone.name}]"
      msg << " - oldest: [#{items.first.created_on.utc.iso8601}], recent: [#{items.last.created_on.utc.iso8601}]" if items.length > 0
      _log.info(msg)
    end
  end
  private_class_method :perf_capture_health_check

  # Collect realtime targets and group them by their rollup parent
  #
  # 1. Only calculate rollups for Hosts
  # 2. Some Hosts have an EmsCluster as a parent, others have none.
  # 3. Only Hosts with a parent are rolled up.
  # 4. Only used for VMWare
  # @param [Array<Host|VmOrTemplate|Storage>] @targets The nodes to rollup
  # @returns Hash<String,Array<Host>>
  #   e.g.: {EmsCluster:4=>[Host:4], EmsCluster:5=>[Host:1, Host:2]}
  def self.calc_targets_by_rollup_parent(targets)
    realtime_targets = targets.select do |target|
      target.kind_of?(Host) &&
        perf_capture_now?(target) &&
        target.ems_cluster_id
    end
    realtime_targets.group_by(&:ems_cluster)
  end

  # Determine queue options for each target
  # Is only generating options for Vmware Hosts, which have a task for rollups.
  # The rest just set the zone
  def self.calc_target_options(zone, targets_by_rollup_parent)
    task_end_time           = Time.now.utc.iso8601
    default_task_start_time = 1.hour.ago.utc.iso8601

    target_options = Hash.new { |h, k| h[k] = {:zone => zone} }
    # Create a new task for each rollup parent
    # mark each target with the rollup parent
    targets_by_rollup_parent.each_with_object(target_options) do |(parent, targets), h|
      pkey = "#{parent.class.name}:#{parent.id}"
      name = "Performance rollup for #{pkey}"
      prev_task = MiqTask.where(:identifier => pkey).order("id DESC").first
      task_start_time = prev_task ? prev_task.context_data[:end] : default_task_start_time

      task = MiqTask.create(
        :name         => name,
        :identifier   => pkey,
        :state        => MiqTask::STATE_QUEUED,
        :status       => MiqTask::STATUS_OK,
        :message      => "Task has been queued",
        :context_data => {
          :start    => task_start_time,
          :end      => task_end_time,
          :parent   => pkey,
          :targets  => targets.map { |target| "#{target.class}:#{target.id}" },
          :complete => [],
          :interval => "realtime"
        }
      )
      _log.info("Created task id: [#{task.id}] for: [#{pkey}] with targets: #{targets_by_rollup_parent[pkey].inspect} for time range: [#{task_start_time} - #{task_end_time}]")
      targets.each do |target|
        h[target] = {
          :task_id => task.id,
          :force   => true, # Force collection since we've already verified that capture should be done now
          :zone    => zone,
        }
      end
    end
  end
  private_class_method :calc_target_options

  # @param targets [Array<Object>] list of the targets for capture (from `capture_ems_targets`)
  # @param target_options [ Hash{Object => Hash{Symbol => Object}}] list of options indexed by target
  def self.queue_captures(targets, target_options)
    targets.each do |target|
      options = target_options[target] || {}
      interval_name = options[:interval] || perf_target_to_interval_name(target)
      target.perf_capture_queue(interval_name, options)
    rescue => err
      _log.warn("Failed to queue perf_capture for target [#{target.class.name}], [#{target.id}], [#{target.name}]: #{err}")
    end
  end
  private_class_method :queue_captures

  def self.perf_target_to_interval_name(target)
    case target
    when Host, VmOrTemplate then                       "realtime"
    when ContainerNode, Container, ContainerGroup then "realtime"
    when Storage then                                  "hourly"
    end
  end
  private_class_method :perf_target_to_interval_name

  def self.minutes_ago(value)
    if value.kind_of?(Integer) # Default unit is minutes
      value.minutes.ago.utc
    elsif value.nil?
      nil
    else
      value.to_i_with_method.seconds.ago.utc
    end
  end
  private_class_method :minutes_ago
end
