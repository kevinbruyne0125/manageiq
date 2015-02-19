module Menu
  class Manager
    include Singleton

    class << self
      extend Forwardable

      delegate [:menu, :tab_features_by_id, :tab_features_by_name, :tab_name,
                :each_feature_title_with_subitems, :item_in_section?] => :instance
    end

    private

    class InvalidMenuDefinition < Exception
    end

    def menu(type = :default)
      @menu.each do |menu_section|
        yield menu_section if menu_section.type == type
      end
    end

    def item_in_section?(item_id, section_id)
      @id_to_section[section_id].items.collect(&:id).include?(item_id)
    end

    def tab_features_by_id(tab_id)
      @id_to_section[tab_id].features
    end

    def tab_features_by_name(tab_name)
      @name_to_section[tab_name].features
    end

    def each_feature_title_with_subitems
      @menu.each { |section| yield section.name, section.features }
    end

    def tab_name(tab_id)
      @id_to_section[tab_id].name
    end

    def initialize
      load_default_items
      load_custom_items
    end

    def merge_sections(sections)
      sections.each do |section|
        if section.after
          position = @menu.index { |existing_section| existing_section.id == section.after }
          @menu.insert(position+1, section)
        else
          @menu << section
        end
      end
    end

    def merge_items(items)
      items.each do |item|
        raise InvalidMenuDefinition, 'Invalid parent' unless @id_to_section.key?(item.parent)
        @id_to_section[item.parent].items << item
      end
    end

    def load_custom_items
      sections, items = Menu::CustomLoader.load
      merge_sections(sections)
      preprocess_sections
      merge_items(items)
    end

    def load_default_items
      @menu = Menu::DefaultMenu.default_menu
      preprocess_sections
    end

    def preprocess_sections
      @id_to_section   = @menu.index_by(&:id)
      @name_to_section = @menu.index_by(&:name)
    end
  end
end
