class ResourceAction < ActiveRecord::Base
  belongs_to :resource, :polymorphic => true
  belongs_to :dialog

  serialize  :ae_attributes, Hash

  def automate_queue_hash(target, override_attrs)
    if target.nil?
      override_values = {}
    elsif target.kind_of?(Hash)
      override_values = target
    else
      override_values = {:object_type => target.class.base_class.name, :object_id => target.id}
    end
    {
      :namespace        => ae_namespace,
      :class_name       => ae_class,
      :instance_name    => ae_instance,
      :automate_message => ae_message,
      :attrs            => (ae_attributes || {}).merge(override_attrs || {}),
    }.merge(override_values).tap do |args|
      args[:user_id]   ||= User.current_user.try(:id)
    end
  end

  def fqname=(value)
    self.ae_namespace, self.ae_class, self.ae_instance, attr_name = MiqAeEngine::MiqAePath.split(value)
  end

  def fqname
    MiqAeEngine::MiqAePath.new(
      :ae_namespace => ae_namespace,
      :ae_class     => ae_class,
      :ae_instance  => ae_instance).to_s
  end
  alias_method :ae_path, :fqname

  def ae_uri
    uri = ae_path
    unless ae_attributes.blank?
      uri << "?"
      uri << MiqAeEngine::MiqAeUri.hash2query(ae_attributes)
    end
    unless ae_message.blank?
      uri << "#"
      uri << ae_message
    end
    uri
  end

  def deliver_to_automate_from_dialog(dialog_hash_values, target)
    _log.info("Queuing <#{self.class.name}:#{id}> for <#{resource_type}:#{resource_id}>")
    MiqAeEngine.deliver_queue(prepare_automate_args(dialog_hash_values, target),
                              :zone     => target.try(:my_zone),
                              :priority => MiqQueue::HIGH_PRIORITY,
                              :task_id  => "#{self.class.name.underscore}_#{id}")
  end

  def deliver_to_automate_from_dialog_field(dialog_hash_values, target)
    _log.info("Running <#{self.class.name}:#{id}> for <#{resource_type}:#{resource_id}>")

    MiqAeEngine.deliver(prepare_automate_args(dialog_hash_values, target))
  end

  def prepare_automate_args(dialog_hash_values, target)
    automate_attrs  = dialog_hash_values[:dialog]
    automate_queue_hash(target, automate_attrs)
  end
end
