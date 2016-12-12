module ManagerRefresh::SaveCollection
  module Helper
    def save_dto_inventory(ems, dto_collection)
      _log.info("Synchronizing #{ems.name} collection #{dto_collection.size} of size #{dto_collection} to database")

      if dto_collection.custom_save_block.present?
        _log.info("Synchronizing #{ems.name} collection #{dto_collection.size} using a custom save block")
        dto_collection.custom_save_block.call(ems, dto_collection)
      else
        save_inventory(dto_collection)
      end
      _log.info("Synchronized #{ems.name} collection #{dto_collection}")
      dto_collection.saved = true
    end

    def log_format_deletes(deletes)
      ret = deletes.collect do |d|
        s = "id: [#{d.id}]"

        [:name, :product_name, :device_name].each do |k|
          next unless d.respond_to?(k)
          v = d.send(k)
          next if v.nil?
          s << " #{k}: [#{v}]"
          break
        end

        s
      end

      ret.join(", ")
    end

    private

    def save_inventory(dto_collection)
      dto_collection.parent.reload if dto_collection.parent
      association  = dto_collection.load_from_db
      record_index = {}

      create_or_update_inventory!(dto_collection, record_index, association)

      # Delete only if DtoCollection is complete. If it's not complete, we are sending only subset of the records, so
      # we cannot invoke deleting of the missing records.
      delete_inventory!(dto_collection, record_index, association) if dto_collection.delete_allowed?
    end

    def create_or_update_inventory!(dto_collection, record_index, association)
      unique_index_keys = dto_collection.manager_ref_to_cols

      association.find_each do |record|
        # TODO(lsmola) the old code was able to deal with duplicate records, should we do that? The old data still can
        # have duplicate methods, so we should clean them up. It will slow up the indexing though.
        record_index[dto_collection.object_index_with_keys(unique_index_keys, record)] = record
      end

      entity_builder = get_entity_builder(dto_collection, association)

      dto_collection_size = dto_collection.size
      created_counter     = 0
      _log.info("*************** PROCESSING #{dto_collection} of size #{dto_collection_size} ***************")
      ActiveRecord::Base.transaction do
        dto_collection.each do |dto|
          hash       = dto.attributes(dto_collection)
          dto.object = record_index.delete(dto.manager_uuid)
          if dto.object.nil?
            next unless dto_collection.create_allowed?
            dto.object      = entity_builder.create!(hash.except(:id))
            created_counter += 1
          else
            dto.object.assign_attributes(hash.except(:id, :type))
            if dto.object.changed?
              dto.object.save!
            end
          end
          dto.object.try(:reload)
        end
      end
      _log.info("*************** PROCESSED #{dto_collection}, created=#{created_counter}, "\
                "updated=#{dto_collection_size - created_counter} ***************")
    end

    def delete_inventory!(dto_collection, record_index, association)
      # Delete the items no longer found
      unless record_index.blank?
        deletes = record_index.values
        _log.info("*************** DELETING #{dto_collection} of size #{deletes.size} ***************")
        type = association.proxy_association.reflection.name
        _log.info("[#{type}] Deleting with method '#{dto_collection.delete_method}' #{log_format_deletes(deletes)}")
        ActiveRecord::Base.transaction do
          deletes.map(&dto_collection.delete_method)
        end
        _log.info("*************** DELETED #{dto_collection} ***************")
      end
    end

    def get_entity_builder(dto_collection, association)
      if dto_collection.parent
        association_meta_info = dto_collection.parent.class.reflect_on_association(dto_collection.association)
        association_meta_info.options[:through].blank? ? association : dto_collection.model_class
      else
        dto_collection.model_class
      end
    end
  end
end
