module Metric::ChargebackHelper
  TAG_MANAGED_PREFIX = "/tag/managed/".freeze

  def tag_prefix
    klass_prefix = case resource_type
                   when Container.name        then 'container_image'
                   when VmOrTemplate.name     then 'vm'
                   when ContainerProject.name then 'container_project'
                   end

    klass_prefix + TAG_MANAGED_PREFIX
  end

  def chargeback_container_labels
    resource.try(:container_image).try(:docker_labels).try(:collect_concat) do |l|
      escaped_name = AssignmentMixin.escape(l.name)
      escaped_value = AssignmentMixin.escape(l.value)
      [
        # The assignments in tags can appear the old way as they are, or escaped
        "container_image/label/managed/#{l.name}/#{l.value}",
        "container_image/label/managed/#{escaped_name}/#{escaped_value}"
      ]
    end || []
  end

  def container_tag_list_with_prefix
    if resource.kind_of?(Container)
      state = resource.vim_performance_state_for_ts(timestamp.to_s)
      image_tag_name = "#{state.image_tag_names}|" if state

      image_tag_name.split("|").reject(&:empty?).map { |x| "#{tag_prefix}#{x}" } + chargeback_container_labels
    else
      []
    end
  end

  def tag_list_with_prefix
    all_tag_names.join("|").split("|").reject(&:empty?).map { |x| "#{tag_prefix}#{x}" } + container_tag_list_with_prefix
  end

  def resource_parents
    [parent_host || resource.try(:host),
     parent_ems_cluster || resource.try(:ems_cluster),
     parent_storage || resource.try(:storage) || resource.try(:cloud_volumes),
     parent_ems || resource.try(:ext_management_system),
     resource.try(:tenant)].flatten.compact
  end

  def parents_determining_rate
    case resource_type
    when VmOrTemplate.name
      (resource_parents + [MiqEnterprise.my_enterprise]).compact
    when ContainerProject.name
      [parent_ems, MiqEnterprise.my_enterprise].compact
    when Container.name
      [parent_ems].compact
    end
  end

  def resource_current_tag_names
    resource ? resource.tags.collect(&:name).map { |x| x.gsub("/managed/", "") } : []
  end

  def resource_tag_names
    tag_names ? tag_names.split("|") : []
  end

  def all_tag_names
    resource_current_tag_names | resource_tag_names
  end
end
