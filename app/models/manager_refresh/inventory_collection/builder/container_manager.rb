module ManagerRefresh
  class InventoryCollection
    class Builder
      class ContainerManager < ::ManagerRefresh::InventoryCollection::Builder
        def container_projects
          add_properties(
            :secondary_refs => {:by_name => %i(name)},
            :delete_method  => :disconnect_inv
          )
          add_common_default_values
        end

        def container_quotas
          add_properties(
            :attributes_blacklist => %i(namespace),
            :delete_method        => :disconnect_inv
          )
          add_common_default_values
        end

        def container_quota_scopes
          add_properties(
            :manager_ref => %i(container_quota scope)
          )
        end

        def container_quota_items
          add_properties(
            :manager_ref    => %i(container_quota resource quota_desired quota_enforced quota_observed),
            :delete_method => :disconnect_inv
          )
        end

        def container_limits
          add_properties(
            :attributes_blacklist => %i(namespace)
          )
          add_common_default_values
        end

        def container_limit_items
          add_properties(
            :manager_ref => %i(container_limit resource item_type)
          )
        end

        def container_nodes
          add_properties(
            :model_class    => ::ContainerNode,
            :secondary_refs => {:by_name => %i(name)},
            :delete_method  => :disconnect_inv
          )
          add_common_default_values
        end

        def computer_systems
          add_properties(:manager_ref => %i(managed_entity))
        end

        def computer_system_hardwares
          add_properties(
            :model_class => ::Hardware,
            :manager_ref => %i(computer_system)
          )
        end

        def computer_system_operating_systems
          add_properties(
            :model_class => ::OperatingSystem,
            :manager_ref => %i(computer_system)
          )
        end

        # images have custom_attributes but that's done conditionally in openshift parser
        def container_images
          add_properties(
            # TODO: (bpaskinc) old save matches on [:image_ref, :container_image_registry_id]
            # TODO: (bpaskinc) should match on digest when available
            :manager_ref            => %i(image_ref),
            :delete_method          => :disconnect_inv,
            :custom_reconnect_block => custom_reconnect_block
          )
          add_common_default_values
        end

        def container_image_registries
          add_properties(:manager_ref => %i(host port))
          add_common_default_values
        end

        def container_groups
          add_properties(
            :secondary_refs         => {:by_container_project_and_name => %i(container_project name)},
            :attributes_blacklist   => %i(namespace),
            :delete_method          => :disconnect_inv,
            :custom_reconnect_block => custom_reconnect_block
          )
          add_common_default_values
        end

        def container_volumes
          add_properties(:manager_ref => %i(parent name))
        end

        def containers
          add_properties(
            :delete_method          => :disconnect_inv,
            :custom_reconnect_block => custom_reconnect_block
          )
          add_common_default_values
        end

        def container_port_configs
          # parser sets :ems_ref => "#{pod_id}_#{container_name}_#{port_config.containerPort}_#{port_config.hostPort}_#{port_config.protocol}"
        end

        def container_env_vars
          add_properties(
            # TODO: (agrare) old save matches on all :name, :value, :field_path - does this matter?
            :manager_ref => %i(container name)
          )
        end

        def security_contexts
          add_properties(:manager_ref => %i(resource))
        end

        def container_replicators
          add_properties(
            :secondary_refs       => {:by_container_project_and_name => %i(container_project name)},
            :attributes_blacklist => %i(namespace)
          )
          add_common_default_values
        end

        def container_services
          add_properties(
            :secondary_refs       => {:by_container_project_and_name => [:container_project, :name]},
            :attributes_blacklist => [:namespace],
            :saver_strategy       => "default" # TODO: (fryguy) (perf) Can't use batch strategy because of usage of M:N container_groups relation
          )
          add_common_default_values
        end

        def container_service_port_configs
          add_properties(:manager_ref => %i(ems_ref protocol)) # TODO(lsmola) make protocol part of the ems_ref?)
        end

        def container_routes
          add_properties(:attributes_blacklist => %i(namespace))
          add_common_default_values
        end

        def container_templates
          add_properties(:attributes_blacklist => %i(namespace))
          add_common_default_values
        end

        def container_template_parameters
          add_properties(:manager_ref => %i(container_template name))
        end

        def container_builds
          add_properties(
            :secondary_refs => {:by_namespace_and_name => %i(namespace name)}
          )
          add_common_default_values
        end

        def container_build_pods
          add_properties(
            # TODO: (bpaskinc) convert namespace column -> container_project_id?
            :manager_ref => %i(namespace name),
            :secondary_refs => {:by_namespace_and_name => %i(namespace name)},
          )
          add_common_default_values
        end

        def persistent_volumes
          add_default_values(:parent => ->(persister) { persister.manager})
        end

        def persistent_volume_claims
          add_properties(
            :secondary_refs       => {:by_container_project_and_name => %i(container_project name)},
            :attributes_blacklist => %i(namespace)
          )
          add_common_default_values
        end
        protected

        def custom_reconnect_block
          # TODO(lsmola) once we have DB unique indexes, we can stop using manual reconnect, since it adds processing time
          lambda do |inventory_collection, inventory_objects_index, attributes_index|
            relation = inventory_collection.model_class.where(:ems_id => inventory_collection.parent.id).archived

            # Skip reconnect if there are no archived entities
            return if relation.archived.count <= 0
            raise "Allowed only manager_ref size of 1, got #{inventory_collection.manager_ref}" if inventory_collection.manager_ref.count > 1

            inventory_objects_index.each_slice(1000) do |batch|
              relation.where(inventory_collection.manager_ref.first => batch.map(&:first)).each do |record|
                index = inventory_collection.object_index_with_keys(inventory_collection.manager_ref_to_cols, record)

                # We need to delete the record from the inventory_objects_index and attributes_index, otherwise it
                # would be sent for create.
                inventory_object = inventory_objects_index.delete(index)
                hash             = attributes_index.delete(index)

                # Make the entity active again, otherwise we would be duplicating nested entities
                hash[:deleted_on] = nil

                record.assign_attributes(hash.except(:id, :type))
                if !inventory_collection.check_changed? || record.changed?
                  record.save!
                  inventory_collection.store_updated_records(record)
                end

                inventory_object.id = record.id
              end
            end
          end
        end
      end
    end
  end
end
