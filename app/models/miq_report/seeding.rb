module MiqReport::Seeding
  extend ActiveSupport::Concern

  REPORT_DIR  = Rails.root.join("product/reports")
  COMPARE_DIR = Rails.root.join("product/compare")

  module ClassMethods
    def seed
      transaction do
        reports = where(:rpt_type => 'Default').where.not(:filename => nil).index_by do |f|
          seed_filename(f.filename)
        end

        seed_files.each do |f|
          seed_record(f, reports.delete(seed_filename(f)))
        end

        if reports.any?
          _log.info("Deleting the following MiqReport(s) as they no longer exist: #{reports.keys.sort.collect(&:inspect).join(", ")}")

          # TODO: Can we make this a delete by getting rid of the dependent destroy on miq_report_result and using the purger?
          MiqReport.destroy(reports.values.map(&:id))
        end
      end
    end

    # Used for seeding a specific report for test purposes
    def seed_report(name)
      path = seed_files.detect { |f| File.basename(f).include?(name) }
      raise "report #{name.inspect} not found" if path.nil?

      seed_record(path, MiqReport.find_by(:filename => seed_filename(path)))
    end

    private

    def seed_record(path, report)
      report ||= MiqReport.new

      # DB and filesystem have different precision so calling round is done in
      # order to eliminate the second fractions diff otherwise the comparison
      # of the file time and the report time from db will always be different.
      mtime = File.mtime(path).utc.round
      report.file_mtime = mtime

      if report.new_record? || report.changed?
        filename = seed_filename(path)

        _log.info("#{report.new_record? ? "Creating" : "Updating"} MiqReport #{filename.inspect}")

        yml   = YAML.load_file(path).symbolize_keys
        attrs = yml.slice(*column_names_symbols)
        attrs.delete(:id)
        attrs[:filename]      = filename
        attrs[:file_mtime]    = mtime
        attrs[:name]          = yml[:menu_name].strip
        attrs[:priority]      = File.basename(path).split("_").first.to_i
        attrs[:rpt_group]     = File.basename(File.dirname(path)).split("_").last
        attrs[:rpt_type]      = "Default"
        attrs[:template_type] = path.start_with?(REPORT_DIR.to_s) ? "report" : "compare"

        report.update_attributes!(attrs)
      end
    end

    def seed_files
      Dir.glob(REPORT_DIR.join("**/*.yaml")).sort + Dir.glob(COMPARE_DIR.join("**/*.yaml")).sort
    end

    def seed_filename(path)
      path.remove("#{REPORT_DIR}/").remove("#{COMPARE_DIR}/")
    end
  end
end
