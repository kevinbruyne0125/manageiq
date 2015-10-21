class MiqEventDefinitionSet < ActiveRecord::Base
  acts_as_miq_set

  default_scope { where conditions_for_my_region_default_scope }

  FIXTURE_DIR = Rails.root.join("db/fixtures")

  def self.seed
    CSV.foreach(FIXTURE_DIR.join("#{to_s.pluralize.underscore}.csv"), :headers => true, :skip_lines => /^#/) do |csv_row|
      set = csv_row.to_hash

      rec = find_by_name(set['name'])
      if rec.nil?
        _log.info("Creating [#{set['name']}]")
        create!(set)
      else
        rec.attributes = set
        if rec.changed?
          _log.info("Updating [#{set['name']}]")
          rec.save!
        end
      end
    end
  end
end
