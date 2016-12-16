class Chargeback
  class RatesCache
    def get(consumption)
      # we need to select ChargebackRates for groups of MetricRollups records
      # and rates are selected by first MetricRollup record
      perf = consumption.first_metric_rollup_record
      @rates ||= {}
      @rates[perf.hash_features_affecting_rate] ||=
        ChargebackRate.get_assigned_for_target(perf.resource,
                                               :tag_list => perf.tag_list_with_prefix,
                                               :parents  => perf.parents_determining_rate)
      if perf.resource_type == Container.name && @rates[perf.hash_features_affecting_rate].empty?
        @rates[perf.hash_features_affecting_rate] = [ChargebackRate.find_by(
          :description => 'Default Container Image Rate', :rate_type => 'Compute')]
      end
      @rates[perf.hash_features_affecting_rate]
    end
  end
end
