FactoryGirl.define do
  factory :miq_request do
    requester { create(:user) }

    factory :automation_request, :class => "AutomationRequest" do
      request_type "automation"
    end

    factory :miq_host_provision_request,         :class => "MiqHostProvisionRequest"
    factory :service_reconfigure_request,        :class => "ServiceReconfigureRequest"
    factory :service_template_provision_request, :class => "ServiceTemplateProvisionRequest" do
      source { create(:service_template) }
    end
    factory :vm_migrate_request,                 :class => "VmMigrateRequest"
    factory :vm_reconfigure_request,             :class => "VmReconfigureRequest"
    factory :miq_provision_request,              :class => "MiqProvisionRequest" do
      source { create(:miq_template) }
    end

    factory :service_template_transformation_plan_request, :class => "ServiceTemplateTransformationPlanRequest" do
      source { create(:service_template_transformation_plan) }
    end
  end
end
