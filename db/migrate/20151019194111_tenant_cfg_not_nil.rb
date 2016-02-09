class TenantCfgNotNil < ActiveRecord::Migration
  class Tenant < ActiveRecord::Base
    self.inheritance_column = :_type_disabled # disable STI
  end

  def up
    say_with_time "Set default for use_config_for_attributes on Tenants" do
      Tenant.where(:use_config_for_attributes => nil).update_all(:use_config_for_attributes => false)
    end
  end
end
