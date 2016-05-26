class TreeBuilderContainers < TreeBuilder
  private

  def tree_init_options(_)
    {
      :leaf     => "Container",
      :open_all => true,
      :full_ids => true
    }
  end

  def set_locals_for_render
    locals = super
    locals.merge!(
      :id_prefix => "container_",
      :autoload  => true
    )
  end

  def x_get_tree_roots(count_only, _options)
    objects = ContainerGroup.where(:deleted_on => nil).order(:name)
    list = objects.compact.map do |c|
      {
        :id          => c.id,
        :text        => c.name,
        :tip         => c.ems_ref,
        :image       => "folder",
        :cfmeNoClick => true
      }
    end
    count_only_or_objects(count_only, list, nil)
  end

  # level 2 - containers
  def x_get_tree_custom_kids(object, count_only, _options)
    container_group = ContainerGroup.find(object[:id])
    objects = rbac_filtered_objects(container_group.containers.where(:deleted_on => nil)) if container_group
    count_only_or_objects(count_only, objects, 'name')
  end
end
