module ManagerRefresh
  class InventoryCollection
    module Index
      class Resolver
        include Vmdb::Logging

        def initialize(inventory_collection, secondary_refs)
          @inventory_collection = inventory_collection

          main_ref       = {:manager_ref => inventory_collection.manager_ref}
          secondary_refs = secondary_refs
          @all_refs      = main_ref.merge(secondary_refs)

          @main_indexes     = {}
          @local_db_indexes = {}

          @all_refs.each do |index_name, attribute_names|
            @main_indexes[index_name] = ManagerRefresh::InventoryCollection::Index::Storage::Main.new(
              inventory_collection,
              attribute_names
            )

            @local_db_indexes[index_name] = ManagerRefresh::InventoryCollection::Index::Storage::LocalDbCache.new(
              inventory_collection,
              attribute_names,
              @main_indexes[index_name]
            )
          end
        end

        def store_indexes_for_inventory_object(inventory_object)
          main_indexes.values.each do |index|
            index.store_index_for(inventory_object)
          end
        end

        def primary_index
          main_index(:manager_ref)
        end

        def find(manager_uuid, ref: :manager_ref)
          # TODO(lsmola) lazy_find will support only hash, then we can remove the _by variant
          return if manager_uuid.nil?

          return unless assert_index(manager_uuid, ref)

          case strategy
          when :local_db_find_references, :local_db_cache_all
            local_db_index(ref).find(manager_uuid)
          when :local_db_find_missing_references
            main_index(ref).find(manager_uuid) || local_db_index(ref).find(manager_uuid)
          else
            main_index(ref).find(manager_uuid)
          end
        end

        def find_by(manager_uuid_hash, ref: :manager_ref)
          # TODO(lsmola) deprecate this, it's enough to have find method
          find(manager_uuid_hash, :ref => ref)
        end

        def lazy_find_by(manager_uuid_hash, ref: :manager_ref, key: nil, default: nil)
          # TODO(lsmola) deprecate this, it's enough to have lazy_find method
          # TODO(lsmola) also, it should be enough to have only 1 find method, everything can be lazy, until we try to
          # access the data
          lazy_find(manager_uuid_hash, :ref => ref, :key => key, :default => default)
        end

        def lazy_find(manager_uuid, ref: :manager_ref, key: nil, default: nil)
          # TODO(lsmola) lazy_find will support only hash, then we can remove the _by variant
          return if manager_uuid.nil?
          # TODO(lsmola) Not doing to_s shows issue in network.orchestration_stack = persister.orchestration_stacks.lazy_find(collector.orchestration_stack_by_resource_id(n.id))
          return unless assert_index(manager_uuid.to_s, ref)

          ::ManagerRefresh::InventoryObjectLazy.new(inventory_collection,
                                                    main_index(ref).object_index(manager_uuid.to_s), # TODO(lsmola) I need to rethink this
                                                    manager_uuid,
                                                    :ref => ref, :key => key, :default => default)
        end

        private

        delegate :strategy, :to => :inventory_collection

        attr_reader :all_refs, :main_indexes, :local_db_indexes, :inventory_collection

        def main_index(name)
          main_indexes[name] || raise("Index #{name} not defined for #{inventory_collection}")
        end

        def local_db_index(name)
          local_db_indexes[name] || raise("Index #{name} not defined for #{inventory_collection}")
        end

        def named_ref(ref)
          all_refs[ref]
        end

        def assert_index(manager_uuid, ref)
          if manager_uuid.kind_of?(Hash)
            # Test we are sending all keys required for the index
            unless (named_ref(ref) - manager_uuid.keys).empty?
              if !Rails.env.production?
                raise "Invalid finder on '#{inventory_collection}' using #{manager_uuid}. Needed find_by keys for #{ref} are #{named_ref(ref)}"
              else
                _log.error("Invalid finder on '#{inventory_collection}' using #{manager_uuid}. Needed find_by keys for #{ref} are #{named_ref(ref)}")
                return false
              end
            end
          else
            # TODO(lsmola) we convert the Hash to String in lazy_find_ so we can't test it like this
            # if named_ref(ref).count > 1
            #   if !Rails.env.production?
            #     raise "Invalid finder on #{inventory_collection} using #{manager_uuid}. We expect Hash with keys #{named_ref(ref)}"
            #   else
            #     _log.error("Invalid finder on #{inventory_collection} using #{manager_uuid}. We expect Hash with keys #{named_ref(ref)}")
            #   end
            # end
          end

          true
        rescue => e
          _log.error("Error when asserting index: #{manager_uuid}, with ref: #{ref} of #{inventory_collection}")
          raise e
        end
      end
    end
  end
end
