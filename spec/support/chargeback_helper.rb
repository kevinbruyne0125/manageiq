module Spec
  module Support
    module ChargebackHelper
      def set_tier_param_for(metric, param, value, num_of_tier = 0)
        tier = chargeback_rate.chargeback_rate_details.where(:metric => metric).first.chargeback_tiers[num_of_tier]
        tier.send("#{param}=", value)
        tier.save
      end
    end
  end
end
