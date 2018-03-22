module TaskHelpers
  class Imports
    class Tags
      class ClassificationYamlError < StandardError
        attr_accessor :details

        def initialize(message = nil, details = nil)
          super(message)
          self.details = details
        end
      end

      def import(options = {})
        return unless options[:source]

        glob = File.file?(options[:source]) ? options[:source] : "#{options[:source]}/*.yaml"
        Dir.glob(glob) do |fname|
          begin
            tag_categories = YAML.load_file(fname)
            import_tags(tag_categories)
          rescue ClassificationYamlError => e
            warn("Error importing #{fname} : #{e.message}")
            e.details.each { |d| warn("\t#{d}") }
          rescue ActiveModel::UnknownAttributeError => e
            warn("Error importing #{fname} : #{e.message}")
          end
        end
      end

      private

      # Tag Categories that are not visible in the UI and should not be imported
      SPECIAL_TAGS = %w(/managed/folder_path_yellow /managed/folder_path_blue /managed/user/role).freeze

      UPDATE_FIELDS = %w(description example_text show perf_by_tag).freeze

      REGION_NUMBER = MiqRegion.my_region_number.freeze

      def import_tags(tag_categories)
        tag_categories.each do |tag_category|
          tag = tag_category["ns"] ? "#{tag_category["ns"]}/#{tag_category["name"]}" : "/managed/#{tag_category["name"]}"
          next if SPECIAL_TAGS.include?(tag)
          Classification.transaction do
            import_classification(tag_category)
          end
        end
      end

      def import_classification(tag_category)
        ns = tag_category["ns"] ? tag_category["ns"] : "/managed"
        tag_category["name"] = tag_category["name"].to_s

        classification = Classification.find_by_name(tag_category['name'], REGION_NUMBER, ns, 0)

        entries = tag_category.delete('entries')

        if classification
          classification.update_attributes!(tag_category.select { |k| UPDATE_FIELDS.include?(k) })
        else
          classification = Classification.create(tag_category)
          raise ClassificationYamlError.new("Tag Category error", classification.errors.full_messages) unless classification.valid?
        end

        import_entries(classification, entries)
      end

      def import_entries(classification, entries)
        errors = []
        entries.each_with_index do |entry, index|
          entry["name"] = entry["name"].to_s
          tag_entry = classification.find_entry_by_name(entry['name'])

          if tag_entry
            tag_entry.update_attributes!(entry.select { |k| UPDATE_FIELDS.include?(k) })
          else
            tag_entry = Classification.create(entry.merge('parent_id' => classification.id))
            unless tag_entry.valid?
              tag_entry.errors.full_messages.each do |message|
                errors << "Entry #{index}: #{message}"
              end
            end
          end
        end
        raise ClassificationYamlError.new("Tag Entry errors", errors) unless errors.empty?
      end
    end
  end
end
