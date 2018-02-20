FactoryGirl.define do
  factory :service_template
  factory :service_template_orchestration, :class => 'ServiceTemplateOrchestration', :parent => :service_template
  factory :service_template_ansible_playbook, :class => 'ServiceTemplateAnsiblePlaybook', :parent => :service_template
  factory :service_template_container_template, :class => 'ServiceTemplateContainerTemplate', :parent => :service_template
  factory :service_template_transformation_plan, :class => 'ServiceTemplateTransformationPlan', :parent => :service_template

  trait :with_provision_resource_action_and_dialog do
    after(:create) do |x|
      x.resource_actions << FactoryGirl.create(:resource_action, :with_dialog, :action => 'Provision')
    end
  end

  trait :orderable do
    display true
    service_template_catalog
  end
end
