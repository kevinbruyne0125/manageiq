class ServicePlan < ApplicationRecord
  belongs_to :ext_management_system, :foreign_key => "ems_id", :inverse_of => :service_plans
  belongs_to :service_offering

  has_many :service_instances, :dependent => :nullify
end
