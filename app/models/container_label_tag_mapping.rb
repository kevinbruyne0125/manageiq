class ContainerLabelTagMapping < ApplicationRecord
  # A mapping matches labels on `resource_type` (NULL means any), `name` (required),
  # and `value` (NULL means any).
  #
  # Different labels might map to same tag, and one label might map to multiple tags.
  #
  # There are 2 kinds of rows:
  # - When `label_value` is specified, we map only this value to a specific `tag`.
  # - When `label_value` is NULL, we map this name with any value to per-value tags.
  #   In this case, `tag` specifies the category under which to create
  #   the value-specific tag (and classification) on demand.
  #   We then also add a specific `label_value`->specific `tag` mapping here.

  belongs_to :tag

  # Returns {name => {type => {value => [tag, ...]}}} hash.
  def self.mappings_hash
    hash = {}
    find_each do |m|
      name, type, value = m.label_name, m.labeled_resource_type, m.label_value
      hash[name] ||= {}
      hash[name][type] ||= {}
      hash[name][type][value] ||= []
      hash[name][type][value] << m.tag
    end
    hash
  end

  def self.all_tags_for_entity(entity)
    hash = mappings_hash

    tags = []
    # Group by label, handle each separately.
    entity.labels.each do |label|
      by_name = hash[label.name] || {}
      # Apply both specific-type and any-type, independently.
      [label.resource_type, nil].each do |type|
        by_name_type = by_name[type] || {}
        specific = by_name_type[label.value] || []
        if !specific.empty?
          tags.concat(specific)
        else
          any_value = by_name_type[nil] || []
          any_value.each do |category_tag|
            # Create a specific-value mapping under same (type-or-nil, name).
            new_tag = create_specific_value_mapping(type, label.name, label.value, category_tag).tag
            specific << new_tag
            tags << new_tag
          end
        end
      end
    end
    tags
  end

  # Finds all existing specific-value tags we're pointing to.  TODO: better name?
  # TODO: cache?
  def self.all_mapped_tags
    Tag.joins(:container_label_tag_mappings).where.not(:container_label_tag_mappings => {:label_value => nil})
  end

  # TODO: before_remove a mapping, clean up tags generated by *that* mapping.

  private

  # If this is an open ended any-value mapping, finds or creates a
  # specific-value mapping to a specific tag.
  def self.create_specific_value_mapping(type, name, value, category_tag)
    create!(
      :labeled_resource_type => type,
      :label_name            => name,
      :label_value           => value,
      :tag                   => create_tag(category_tag, value)
    )
  end
  private_class_method :create_specific_value_mapping

  def self.create_tag(category_tag, value)
    entry_name = Classification.sanitize_name(value)
    # TODO: support /ns/category Tag that has no Classification?
    category = category_tag.classification
    entry = category.add_entry(:name => entry_name, :description => value)
    entry.save!
    entry.tag
  end
  private_class_method :create_tag
end
