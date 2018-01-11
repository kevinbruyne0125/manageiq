module ManagerRefresh
  class InventoryCollection
    class Scanner
      class << self
        # Scanning inventory_collections for dependencies and references, storing the results in the inventory_collections
        # themselves. Dependencies are needed for building a graph, references are needed for effective DB querying, where
        # we can load all referenced objects of some InventoryCollection by one DB query.
        #
        # @param inventory_collections [Array] Array fo
        def scan!(inventory_collections)
          indexed_inventory_collections = inventory_collections.index_by(&:name)

          inventory_collections.each do |inventory_collection|
            new(inventory_collection, indexed_inventory_collections).scan!
          end

          inventory_collections.each do |inventory_collection|
            inventory_collection.dependencies.each do |dependency|
              dependency.dependees << inventory_collection
            end
          end
        end
      end

      attr_reader :inventory_collection, :indexed_inventory_collections

      # Boolean helpers the scanner uses from the :inventory_collection
      delegate :inventory_object_lazy?,
               :inventory_object?,
               :targeted?,
               :to => :inventory_collection

      # Methods the scanner uses from the :inventory_collection
      delegate :data,
               :find_or_build,
               :manager_ref,
               :saver_strategy,
               :to => :inventory_collection

      # The data scanner modifies inside of the :inventory_collection
      delegate :attribute_references,
               :data_collection_finalized=,
               :dependency_attributes,
               :manager_uuids,
               :parent_inventory_collections,
               :parent_inventory_collections=,
               :references,
               :skeletal_manager_uuids,
               :transitive_dependency_attributes,
               :to => :inventory_collection

      def initialize(inventory_collection, indexed_inventory_collections)
        @inventory_collection          = inventory_collection
        @indexed_inventory_collections = indexed_inventory_collections
      end

      def scan!
        # Scan InventoryCollection InventoryObjects and store the results inside of the InventoryCollection
        data.each do |inventory_object|
          scan_inventory_object!(inventory_object)

          if targeted? && parent_inventory_collections.blank?
            # We want to track what manager_uuids we should query from a db, for the targeted refresh
            # TODO(lsmola) this has to track references
            manager_uuid = inventory_object.manager_uuid
            manager_uuids << manager_uuid if manager_uuid
          end
        end

        # Transform :parent_inventory_collections symbols to InventoryCollection objects
        if parent_inventory_collections.present?
          self.parent_inventory_collections = parent_inventory_collections.map do |inventory_collection_index|
            ic = indexed_inventory_collections[inventory_collection_index]
            if ic.nil?
              raise "Can't find InventoryCollection #{inventory_collection_index} from #{inventory_collection}" if targeted?
            else
              # Add parent_inventory_collection as a dependency, so e.g. disconnect is done in a right order
              (dependency_attributes[:__parent_inventory_collections] ||= Set.new) << ic
              ic
            end
          end.compact
        end

        # Mark InventoryCollection as finalized aka. scanned
        self.data_collection_finalized = true
      end

      private

      def scan_inventory_object!(inventory_object)
        inventory_object.data.each do |key, value|
          if value.kind_of?(Array)
            value.each { |val| scan_inventory_object_attribute!(key, val) }
          else
            scan_inventory_object_attribute!(key, value)
          end
        end
      end

      def scan_inventory_object_attribute!(key, value)
        return if !inventory_object_lazy?(value) && !inventory_object?(value)
        value_inventory_collection = value.inventory_collection

        # Storing attributes and their dependencies
        (dependency_attributes[key] ||= Set.new) << value_inventory_collection if value.dependency?

        # Storing a reference in the target inventory_collection, then each IC knows about all the references and can
        # e.g. load all the referenced uuids from a DB
        value_inventory_collection.add_reference(value.reference, :key => value.try(:key))

        skeletal_precreate(value_inventory_collection, value)

        if inventory_object_lazy?(value)
          # Storing if attribute is a transitive dependency, so a lazy_find :key results in dependency
          transitive_dependency_attributes << key if value.transitive_dependency?
        end
      end


      # Instead of loading the reference from the DB, we'll add the skeletal InventoryObject (having manager_ref and
      # info from the builder_params) to the correct InventoryCollection. Which will either be found in the DB or
      # created as a skeletal object. The later refresh of the object will then fill the rest of the data, while not
      # touching the reference.
      # @param value_inventory_collection [InventoryCollection] Inventory collection of the value
      # @param value [InventoryObjectLazy] Scanned InventoryObject or lazy link
      def skeletal_precreate(value_inventory_collection, value)
        # For concurrent safe strategies, we want to pre-build the relations using the lazy_link data, so we can fill up
        # the foreign key in first pass.
        return unless [:concurrent_safe, :concurrent_safe_batch].include?(saver_strategy)

        # To be able to do the skeletal precreate, we need InventoryObjectLazy, that needs to be a dependency
        return unless inventory_object_lazy?(value) && value.dependency?
        # TODO(lsmola) solve the :key, since that requires data from the actual reference. At best our DB should be
        # designed the way, we don't duplicate the data, but rather get them with a join. (3NF!)

        # We can only do skeletal pre-create for primary index reference
        return unless value.reference.primary?

        return if (full_reference = value.reference.full_reference).blank?

        # TODO(lsmola) we need to do a recursive skeletal precreate
        # Do a skeletal precreate of InventoryObject in value_inventory_collection, using full reference
        value_inventory_collection.build(full_reference)

        # TODO(what do I need this for?)
        value_inventory_collection.skeletal_manager_uuids << value.stringified_reference
      end
    end
  end
end
