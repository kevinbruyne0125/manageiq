module ManagerRefresh
  class InventoryCollection
    class DataStorage
      include Vmdb::Logging

      # @return [Array<InventoryObject>] objects of the InventoryCollection in an Array
      attr_accessor :data

      attr_reader :index_proxy, :inventory_collection

      delegate :each, :size, :to => :data

      delegate :primary_index,
               :build_primary_index_for,
               :build_secondary_indexes_for,
               :named_ref,
               :to => :index_proxy

      delegate :builder_params,
               :inventory_object?,
               :inventory_object_lazy?,
               :manager_ref,
               :new_inventory_object,
               :to => :inventory_collection

      def initialize(inventory_collection, secondary_refs)
        @inventory_collection = inventory_collection
        @data                 = []

        @index_proxy = ManagerRefresh::InventoryCollection::Index::Proxy.new(inventory_collection, secondary_refs)
      end

      def <<(inventory_object)
        if inventory_object.manager_uuid.present? && !primary_index.find(inventory_object.manager_uuid)
          data << inventory_object

          # TODO(lsmola) Maybe we do not need the secondary indexes here?
          # Maybe we should index it like LocalDb indexes, on demand, and storing what was
          # indexed? Maybe we should allow only lazy access and no direct find from a parser. Since for streaming
          # refresh, things won't be parsed together and no full state will be taken.
          build_primary_index_for(inventory_object)
          build_secondary_indexes_for(inventory_object)
        end
        inventory_collection
      end

      alias push <<

      def find_or_build(manager_uuid)
        raise "The uuid consists of #{manager_ref.size} attributes, please find_or_build_by method" if manager_ref.size > 1

        find_or_build_by(manager_ref.first => manager_uuid)
      end

      def find_or_build_by(manager_uuid_hash)
        find_in_data(manager_uuid_hash) || build(manager_uuid_hash)
      end

      def find_in_data(hash)
        hash = enrich_data(hash)

        if manager_ref.any? { |x| !hash.key?(x) }
          raise "Needed find_or_build_by keys are: #{manager_ref}, data provided: #{hash}"
        end

        uuid = ::ManagerRefresh::InventoryCollection::Reference.build_stringified_reference(hash, named_ref)
        primary_index.find(uuid)
      end

      def build(hash)
        # Build the InventoryObject
        inventory_object = new_inventory_object(enrich_data(hash))
        # Store new InventoryObject and return it
        push(inventory_object)

        return inventory_object unless inventory_object.nil?

        # TODO(lsmola) prepare for changing behavior, build will return nil if it can't build or the record is already
        # there. Maybe we should even make build a private method.
        find_in_data(enrich_data(hash))
      end

      def to_a
        data
      end

      # Import/export methods
      def from_raw_data(inventory_objects_data, available_inventory_collections)
        inventory_objects_data.each do |inventory_object_data|
          hash = inventory_object_data.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = if value.kind_of?(Array)
                                   value.map { |x| from_raw_value(x, available_inventory_collections) }
                                 else
                                   from_raw_value(value, available_inventory_collections)
                                 end
          end
          build(hash)
        end
      end

      def from_raw_value(value, available_inventory_collections)
        if value.kind_of?(Hash) && (value['type'] || value[:type]) == "ManagerRefresh::InventoryObjectLazy"
          value.transform_keys!(&:to_s)
        end

        if value.kind_of?(Hash) && value['type'] == "ManagerRefresh::InventoryObjectLazy"
          inventory_collection = available_inventory_collections[value['inventory_collection_name'].try(:to_sym)]
          raise "Couldn't build lazy_link #{value} the inventory_collection_name was not found" if inventory_collection.blank?
          inventory_collection.lazy_find(value['ems_ref'], :key => value['key'], :default => value['default'])
        else
          value
        end
      end

      def to_raw_data
        data.map do |inventory_object|
          inventory_object.data.transform_values do |value|
            if inventory_object_lazy?(value)
              value.to_raw_lazy_relation
            elsif value.kind_of?(Array) && (inventory_object_lazy?(value.compact.first) || inventory_object?(value.compact.first))
              value.compact.map(&:to_raw_lazy_relation)
            elsif inventory_object?(value)
              value.to_raw_lazy_relation
            else
              value
            end
          end
        end
      end

      private

      def enrich_data(hash)
        # This is 25% faster than builder_params.merge(hash)
        {}.merge!(builder_params).merge!(hash)
      end
    end
  end
end
