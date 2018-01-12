module ManagerRefresh
  class InventoryObjectLazy
    include Vmdb::Logging

    attr_reader :reference, :inventory_collection, :key, :default

    delegate :stringified_reference, :ref, :[], :to => :reference

    def initialize(inventory_collection, index_data, ref: :manager_ref, key: nil, default: nil)
      @inventory_collection = inventory_collection
      @reference            = inventory_collection.build_reference(index_data, ref)
      @key                  = key
      @default              = default

      # We do not support skeletal pre-create for :key, since :key will not be available, we want to use local_db_find
      # instead.
      skeletal_precreate! unless @key
    end

    # TODO(lsmola) do we need this method?
    def to_s
      stringified_reference
    end

    def inspect
      suffix = ""
      suffix += ", ref: #{ref}" if ref.present?
      suffix += ", key: #{key}" if key.present?
      "InventoryObjectLazy:('#{self}', #{inventory_collection}#{suffix})"
    end

    def to_raw_lazy_relation
      {
        :type                      => "ManagerRefresh::InventoryObjectLazy",
        :inventory_collection_name => inventory_collection.name,
        :reference                 => reference.to_hash,
        :key                       => key,
        :default                   => default,
      }
    end

    def load
      key ? load_object_with_key : load_object
    end

    def dependency?
      # If key is not set, InventoryObjectLazy is a dependency, cause it points to the record itself. Otherwise
      # InventoryObjectLazy is a dependency only if it points to an attribute which is a dependency or a relation.
      !key || transitive_dependency?
    end

    def transitive_dependency?
      # If the dependency is inventory_collection.lazy_find(:ems_ref, :key => :stack)
      # and a :stack is a relation to another object, in the InventoryObject object,
      # then this relation is considered transitive.
      key && association?(key)
    end

    # Return if the key is an association on inventory_collection_scope model class
    def association?(key)
      # TODO(lsmola) remove this if there will be better dependency scan, probably with transitive dependencies filled
      # in a second pass, then we can get rid of this hardcoded symbols. Right now we are not able to introspect these.
      return true if [:parent, :genelogy_parent].include?(key)

      inventory_collection.dependency_attributes.key?(key) ||
        !inventory_collection.association_to_foreign_key_mapping[key].nil?
    end

    private

    delegate :saved?, :saver_strategy, :targeted?, :to => :inventory_collection
    delegate :full_reference, :keys, :primary?, :to => :reference


    # Instead of loading the reference from the DB, we'll add the skeletal InventoryObject (having manager_ref and
    # info from the builder_params) to the correct InventoryCollection. Which will either be found in the DB or
    # created as a skeletal object. The later refresh of the object will then fill the rest of the data, while not
    # touching the reference.
    # @return [ManagerRefresh::InventoryObject| Returns pre-created InvetoryObject or nil
    def skeletal_precreate!
      # We can do skeletal pre-create only for strategies using unique indexes. Since this can build records out of
      # the given :arel scope, we will always attempt to create the recod, so we need unique index to avoid duplication
      # of records.
      return unless %i(concurrent_safe concurrent_safe_batch).include?(saver_strategy)
      # Allow skeletal pre-create only for targeted refresh, full refresh should have all edges connected
      # TODO(lsmola) actually this is not true, e.g. cloud have several full refreshes, where e.g. storage manager
      # records can have missing edges to cloud manager records. For this to drop, we need build method to call
      # assign_attributes, or use everywhere find_or_build(hash).assign_attributes(hash)
      return unless targeted?
      # Pre-create only for strategies that will be persisting data, i.e. are not saved already
      return if saved?
      # We can only do skeletal pre-create for primary index reference, since that is needed to create DB unique index
      return unless primary?
      # Full reference must be present
      return if full_reference.blank?

      # To avoid pre-creating invalid records all fields of a primary key must have value
      # TODO(lsmola) for composite keys, it's still valid to have one of the keys nil, figure out how to allow this
      return if keys.any? { |x| full_reference[x].blank? }

      inventory_collection.build(full_reference)

      # TODO(lsmola) what do I need this for? Skeletal record can break :key, since the record won't be fetched by DB
      # strategy and :key is missing in skeletal record. Write spec!
      # value_inventory_collection.skeletal_manager_uuids << value.stringified_reference
    end

    def load_object_with_key
      # TODO(lsmola) Log error if we are accessing path that is present in blacklist or not present in whitelist
      found = inventory_collection.find(reference)
      if found.present?
        if found.try(:data).present?
          found.data[key] || default
        else
          found.public_send(key) || default
        end
      else
        default
      end
    end

    def load_object
      inventory_collection.find(reference)
    end
  end
end
