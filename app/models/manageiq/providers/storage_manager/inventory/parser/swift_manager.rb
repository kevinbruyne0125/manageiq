class ManageIQ::Providers::StorageManager::Inventory::Parser::SwiftManager < ManageIQ::Providers::StorageManager::Inventory::Parser
  def parse
    collector.directories.each do |dir|
      persister_conatiner = parse_container(dir)
      collector.files(dir).each do |file|
        parse_object(file, persister_conatiner)
      end
    end
  end

  def parse_container(container)
    persister.cloud_object_store_containers.build(
      :ems_ref      => container_ems_ref(container),
      :key          => container.key,
      :object_count => container.count,
      :bytes        => container.bytes
    )
  end

  def parse_object(object, persister_conatiner)
    persister.cloud_object_store_objects.build(
      :ems_ref                      => object.key,
      :etag                         => object.etag,
      :last_modified                => object.last_modified,
      :content_length               => object.content_length,
      :content_type                 => object.content_type,
      :key                          => object.key,
      :cloud_object_store_container => persister_conatiner
    )
  end

  private

  def container_ems_ref(container)
    "#{container.project.id}/#{container.key}"
  end
end
