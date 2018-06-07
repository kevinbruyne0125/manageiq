class Chargeback
  class ConsumptionHistory
    def self.for_report(cb_class, options, region)
      base_rollup = base_rollup_scope.in_region(region)
      timerange = options.report_time_range
      interval_duration = options.duration_of_report_step

      extra_resources = cb_class.try(:extra_resources_without_rollups, region) || []
      timerange.step_value(interval_duration).each_cons(2) do |query_start_time, query_end_time|
        extra_resources.each do |resource|
          consumption = ConsumptionWithoutRollups.new(resource, query_start_time, query_end_time)
          yield(consumption) unless consumption.consumed_hours_in_interval.zero?
        end

        next unless options.include_metrics?

        records = MetricRollup.where(:timestamp => query_start_time...query_end_time, :capture_interval_name => 'hourly')
        records = cb_class.where_clause(records, options, region)
        records = uniq_timestamp_record_map(records, options.group_by_tenant?)

        next if records.empty?
        _log.info("Found #{records.length} records for time range #{[query_start_time, query_end_time].inspect}")

        # we are building hash with grouped calculated values
        # values are grouped by resource_id and timestamp (query_start_time...query_end_time)

        records.each_value do |rollup_record_ids|
          metric_rollup_records = base_rollup.where(:id => rollup_record_ids).to_a
          consumption = ConsumptionWithRollups.new(metric_rollup_records, query_start_time, query_end_time)
          yield(consumption) unless consumption.consumed_hours_in_interval.zero?
        end
      end
    end

    def self.base_rollup_scope
      base_rollup = MetricRollup.includes(
        :resource           => [:hardware, :tenant, :tags, :vim_performance_states, :custom_attributes,
                                {:container_image => :custom_attributes}],
        :parent_host        => :tags,
        :parent_ems_cluster => :tags,
        :parent_storage     => :tags,
        :parent_ems         => :tags)
                                .select(*(Metric::BASE_COLS + ChargeableField.chargeable_cols_on_metric_rollup)).order('resource_id, timestamp')

      base_rollup.with_resource
    end

    private_class_method :base_rollup_scope

    def self.uniq_timestamp_record_map(report_scope, group_by_tenant = false)
      main_select = MetricRollup.select(:id, :resource_id).arel.ast.to_sql
                                .gsub("SELECT", "DISTINCT ON (resource_type, resource_id, timestamp)")
                                .gsub(/ FROM.*$/, '')

      query = report_scope.select(main_select)
                          .order(:resource_type, :resource_id, :timestamp)
                          .order("created_on DESC")

      rows = ActiveRecord::Base.connection.select_rows(query.to_sql)

      if group_by_tenant
        vms = Hash[Vm.where(:id => rows.map(&:second)).pluck(:id, :tenant_id)]
      end

      rows.each_with_object({}) do |(id, resource_id), result|
        resource_id = vms[resource_id] if group_by_tenant
        result[resource_id] ||= []
        result[resource_id] << id
      end
    end

    private_class_method :uniq_timestamp_record_map
  end
end
