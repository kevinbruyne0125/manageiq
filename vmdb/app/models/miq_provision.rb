class MiqProvision < MiqProvisionTask
  include MiqProvisionMixin
  include_concern 'Automate'
  include_concern 'CustomAttributes'
  include_concern 'Description'
  include_concern 'Genealogy'
  include_concern 'PostInstallCallback'
  include_concern 'Helper'
  include_concern 'Iso'
  include_concern 'Naming'
  include_concern 'OptionsHelper'
  include_concern 'Ownership'
  include_concern 'Pxe'
  include_concern 'Retirement'
  include_concern 'Service'
  include_concern 'StateMachine'
  include_concern 'Tagging'

  alias_attribute :vm,          :destination
  alias_attribute :vm_template, :source

  before_create :set_template_and_networking

  virtual_belongs_to :vm
  virtual_belongs_to :vm_template
  virtual_column     :provision_type, :type => :string
  virtual_column     :placement_auto, :type => :boolean

  CLONE_SYNCHRONOUS     = false
  CLONE_TIME_LIMIT      = 4.hours
  SUBCLASSES            = %w{MiqProvisionCloud MiqProvisionRedhat MiqProvisionVmware}
  SUPPORTED_EMS_CLASSES = %w{EmsVmware EmsRedhat EmsAmazon EmsOpenstack}

  def self.base_model
    MiqProvision
  end

  def set_template_and_networking
    self.source = get_source

    set_static_ip_address
    set_dns_domain
  end

  def deliver_to_automate
    super("vm_provision", my_zone)
  end

  def execute_queue
    super(:zone        => my_zone,
          :msg_timeout => CLONE_SYNCHRONOUS ? CLONE_TIME_LIMIT : MiqQueue::TIMEOUT)
  end

  def placement_auto
    get_option(:placement_auto)
  end

  def after_request_task_create
    vm_name                           = self.get_next_vm_name
    self.options[:vm_target_name]     = vm_name
    self.options[:vm_target_hostname] = get_hostname(vm_name)
    self.description                  = self.class.get_description(self, vm_name)
    self.save
  end

  def after_ae_delivery(ae_result)
    log_header = "MIQ(#{self.class.name}.after_ae_delivery)"

    $log.info("#{log_header} ae_result=#{ae_result.inspect}")

    return if ae_result == 'retry'
    return if self.miq_request.state == 'finished'

    if ae_result == 'ok'
      update_and_notify_parent(:state => "finished", :status => "Ok",    :message => "#{self.request_class::TASK_DESCRIPTION} completed")
    else
      update_and_notify_parent(:state => "finished", :status => "Error" )
    end
  end

  def self.get_description(prov_obj, vm_name)
    request_type = prov_obj.options[:request_type]
    title = case request_type
            when :clone_to_vm       then "Clone"
            when :clone_to_template then "Publish"
            else "Provision"
            end

    "#{title} from [#{prov_obj.vm_template.name}] to [#{vm_name}]"
  end
end

# Preload any subclasses of this class, so that they will be part of the
#   conditions that are generated on queries against this class.
MiqProvision::SUBCLASSES.each { |c| require_dependency Rails.root.join("app", "models", "#{c.underscore}.rb").to_s }
