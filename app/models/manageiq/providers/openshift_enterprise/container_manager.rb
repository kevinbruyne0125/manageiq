class ManageIQ::Providers::OpenshiftEnterprise::ContainerManager < ManageIQ::Providers::ContainerManager
  include ManageIQ::Providers::Openshift::ContainerManagerMixin

  require_nested :EventCatcher
  require_nested :EventParser
  require_nested :MetricsCollectorWorker
  require_nested :RefreshParser
  require_nested :RefreshWorker
  require_nested :Refresher

  def self.ems_type
    @ems_type ||= "openshift_enterprise".freeze
  end

  def self.description
    @description ||= "OpenShift Enterprise".freeze
  end

  def self.event_monitor_class
    ManageIQ::Providers::OpenshiftEnterprise::ContainerManager::EventCatcher
  end
end
