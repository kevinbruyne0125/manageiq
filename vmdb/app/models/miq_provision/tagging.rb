module MiqProvision::Tagging
  def get_user_managed_filters
    user = get_user
    user && user.get_managed_filters.flatten
  end

  def allowed_tags_by_category(category_name)
    user_tags = self.get_user_managed_filters
    category = Classification.find_by_name(category_name)
    raise MiqException::MiqProvisionError, "unknown category, '#{category_name}'" if category.nil?
    category.entries.each_with_object({}) do |entry, h|
      if user_tags.blank? || user_tags.include?(entry.to_tag)
        h[entry.name] = entry.description
      end
    end
  end
end
