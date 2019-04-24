module Spec
  module Support
    module ChargebackHelper
      def set_tier_param_for(metric, param, value, num_of_tier = 0)
        detail = chargeback_rate.chargeback_rate_details.joins(:chargeable_field).where(:chargeable_fields => { :metric => metric }).first
        tier = detail.chargeback_tiers[num_of_tier]
        tier.send("#{param}=", value)
        tier.save
      end

      def used_average_for(metric, hours_in_interval, resource)
        resource.metric_rollups.sum(&metric) / hours_in_interval
      end

      def add_metric_rollups_for(resources, range, step, metric_rollup_params, trait = [:with_data])
        args          = ([:metric_rollup_vm_hr] + trait).compact
        times         = range.step_value(step).to_a
        column_names  = nil
        record_values = []

        Array(resources).each do |resource|
          resource_attrs = {
            :resource_id   => resource.id,
            :resource_name => resource.name,
            :resource_type => resource.class.base_class.name
          }

          attrs = FactoryBot.attributes_for(*args, metric_rollup_params.merge(resource_attrs))
          attrs.delete(:timestamp)

          column_names ||= attrs.keys.append("timestamp").join(", ")
          base_values    = attrs.values.map(&:inspect).join(", ").tr('"', "'")

          times.each do |time|
            record_values << "(#{base_values}, '#{time.to_s(:db)}')"
          end
        end

        insert_statement = "INSERT INTO #{MetricRollup.table_name}"
        insert_statement << " (#{column_names}) VALUES "
        insert_statement << record_values.join(", ")

        ActiveRecord::Base.connection.execute(insert_statement)
      end

      def add_vim_performance_state_for(resources, range, step, state_data)
        range.step_value(step).each do |time|
          Array(resources).each do |resource|
            FactoryBot.create(:vim_performance_state,
                               :timestamp        => time,
                               :resource         => resource,
                               :state_data       => state_data,
                               :capture_interval => 1.hour)
          end
        end
      end
    end
  end
end
