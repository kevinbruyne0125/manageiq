module ManagerRefresh
  class InventoryCollection
    # @see test in /spec/models/manager_refresh/inventory_collection/builder_spec.rb
    class Builder
      class MissingModelClassError < StandardError; end

      require_nested :CloudManager
      require_nested :InfraManager
      require_nested :AutomationManager
      require_nested :NetworkManager
      require_nested :StorageManager
      require_nested :PersisterHelper

      include ::ManagerRefresh::InventoryCollection::Builder::Shared

      # Default options for builder
      #   :adv_settings
      #     - values from Advanced settings (doesn't overwrite values specified in code)
      #     - @see method ManagerRefresh::Inventory::Persister.make_builder_settings()
      #   :shared_properties
      #     - any properties applied if missing (not explicitly specified)
      def self.default_options
        {
          :adv_settings      => {},
          :shared_properties => {},
        }
      end

      # Entry point
      # Creates builder and builds data for inventory collection
      # @param name [Symbol] InventoryCollection.association value
      #        (optional) method with this name also used for concrete inventory collection specific properties
      # @param persister_class [Class] used for "guessing" model_class
      # @param options [Hash]
      def self.prepare_data(name, persister_class, options = {})
        options = default_options.merge(options)
        builder = new(name, persister_class, options)
        builder.construct_data

        yield(builder) if block_given?

        builder
      end

      # @see prepare_data()
      def initialize(name, persister_class, options = self.class.default_options)
        @name = name
        @persister_class = persister_class

        @properties = {}
        @inventory_object_attributes = []
        @default_values = {}
        @dependency_attributes = {}

        @options = options
        @options[:auto_inventory_attributes] = true if @options[:auto_inventory_attributes].nil?
        @options[:without_model_class] = false if @options[:without_model_class].nil?

        @adv_settings = options[:adv_settings] # Configuration/Advanced settings in GUI
        @shared_properties = options[:shared_properties] # From persister
      end

      # Builds data for InventoryCollection
      # Calls method @name (if exists) with specific properties
      # Yields for overwriting provider-specific properties
      def construct_data
        add_properties(:association => @name)
        add_properties(:model_class => auto_model_class) unless @options[:without_model_class]

        add_properties(@adv_settings, :if_missing)
        add_properties(@shared_properties, :if_missing)

        send(@name.to_sym) if respond_to?(@name.to_sym)

        add_inventory_attributes(auto_inventory_attributes) if @options[:auto_inventory_attributes]
      end

      # Creates InventoryCollection
      def to_inventory_collection
        if @properties[:model_class].nil? && !@options[:without_model_class]
          raise MissingModelClassError
        end

        ::ManagerRefresh::InventoryCollection.new(to_hash)
      end

      #
      # Missing method
      #   - add_some_property(value)
      # converted to:
      #   - add_properties(:some_property => value)
      #
      def method_missing(method_name, *arguments, &block)
        if method_name.to_s.starts_with?('add_')
          add_properties(
            method_name.to_s.gsub('add_', '').to_sym => arguments[0]
          )
        else
          super
        end
      end

      def respond_to_missing?(method_name, _include_private = false)
        method_name.to_s.starts_with?('add_')
      end

      # Merges @properties
      # @see ManagerRefresh::InventoryCollection.initialize for list of properties
      #
      # @param props [Hash]
      # @param mode [Symbol] :overwrite | :if_missing
      def add_properties(props = {}, mode = :overwrite)
        @properties = merge_hashes(@properties, props, mode)
      end

      # Adds inventory object attributes (part of @properties)
      def add_inventory_attributes(array)
        @inventory_object_attributes += (array || [])
      end

      # Removes specified inventory object attributes
      def remove_inventory_attributes(array)
        @inventory_object_attributes -= (array || [])
      end

      # Clears all inventory object attributes
      def clear_inventory_attributes!
        @inventory_object_attributes = []
      end

      # Adds key/values to default values (InventoryCollection.builder_params) (part of @properties)
      def add_default_values(params = {}, mode = :overwrite)
        @default_values = merge_hashes(@default_values, params, mode)
      end
      alias add_builder_params add_default_values

      # Evaluates lambda blocks
      def evaluate_lambdas!(persister)
        @default_values = evaluate_lambdas_on(@default_values, persister)
        @dependency_attributes = evaluate_lambdas_on(@dependency_attributes, persister)
      end

      # Adds key/values to dependency_attributes (part of @properties)
      def add_dependency_attributes(attrs = {}, mode = :overwrite)
        @dependency_attributes = merge_hashes(@dependency_attributes, attrs, mode)
      end

      # Deletes key from dependency_attributes
      def remove_dependency_attributes(key)
        @dependency_attributes.delete(key)
      end

      # Returns whole InventoryCollection properties
      # TODO: default values converted to builder_params, change InventoryCollection and usages in next PR
      def to_hash
        @properties.merge(
          :inventory_object_attributes => @inventory_object_attributes,
          :builder_params              => @default_values,
          :dependency_attributes       => @dependency_attributes
        )
      end

      protected

      # Extends source hash with
      # - a) all keys from dest (overwrite mode)
      # - b) missing keys (missing mode)
      #
      # @param mode [Symbol] :overwrite | :if_missing
      def merge_hashes(source, dest, mode)
        return source if source.nil? || dest.nil?

        if mode == :overwrite
          source.merge(dest)
        else
          dest.merge(source)
        end
      end

      # Derives model_class from persister class and @name
      # 1) searches for class in provider
      # 2) if not found, searches class in core
      # Can be disabled by options :auto_model_class => false
      #
      # @example derives model_class from amazon
      #
      #   @persister_class = ManageIQ::Providers::Amazon::Inventory::Persister::CloudManager
      #   @name = :vms
      #
      #   returns - <provider_module>::<manager_module>::<@name.classify>
      #   returns - ::ManageIQ::Providers::Amazon::CloudManager::Vm
      #
      # @example derives model_class from @name only
      #
      #   @persister_class = ManagerRefresh::Inventory::Persister
      #   @name = :vms
      #
      #   returns ::Vm
      #
      # @return [Class | nil] when class doesn't exist, returns nil
      def auto_model_class
        model_class = begin
          # a) Provider specific class
          provider_module = ManageIQ::Providers::Inflector.provider_module(@persister_class).name
          manager_module = self.class.name.split('::').last

          class_name = "#{provider_module}::#{manager_module}::#{@name.to_s.classify}"
          class_name.safe_constantize
        rescue ::ManageIQ::Providers::Inflector::ObjectNotNamespacedError
          nil
        end

        if model_class
          model_class
        else
          # b) general class
          "::#{@name.to_s.classify}".safe_constantize
        end
      end

      # Inventory object attributes are derived from setters
      #
      # Can be disabled by options :auto_inventory_attributes => false
      #   - attributes can be manually set via method add_inventory_attributes()
      def auto_inventory_attributes
        return if @properties[:model_class].nil?

        (@properties[:model_class].new.methods - ApplicationRecord.methods).grep(/^[\w]+?\=$/).collect do |setter|
          setter.to_s[0..setter.length - 2].to_sym
        end
      end

      # Evaluates lambda blocks in @default_values and @dependency_attributes
      # @param values[Hash]
      # @param persister [ManagerRefresh::Inventory::Persister]
      def evaluate_lambdas_on(values, persister)
        if values
          values.transform_values do |value|
            if value.respond_to?(:call)
              value.call(persister)
            else
              value
            end
          end
        end
      end
    end
  end
end
