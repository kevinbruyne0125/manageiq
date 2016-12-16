class Chargeback
  class Consumption
    delegate :timestamp, :resource, :resource_id, :resource_name, :parent_ems, :to => :first_metric_rollup_record

    def initialize(metric_rollup_records, start_time, end_time)
      @rollups = metric_rollup_records
      @start_time, @end_time = start_time, end_time
    end

    def first_metric_rollup_record
      @rollups.first
    end

    def tag_names
      first_metric_rollup_record.tag_names.split('|')
    end

    def max(metric)
      values(metric).max
    end

    def avg(metric)
      metric_sum = values(metric).sum
      metric_sum / hours_in_interval
    end

    def none?(metric)
      values(metric).empty?
    end

    def chargeback_fields_present
      @chargeback_fields_present ||= @rollups.count(&:chargeback_fields_present?)
    end

    def hours_in_interval
      @hours_in_interval ||= (@end_time - @start_time).round / 1.hour
    end

    private

    def values(metric)
      @values ||= {}
      @values[metric] ||= @rollups.collect(&metric.to_sym).compact
    end
  end
end
