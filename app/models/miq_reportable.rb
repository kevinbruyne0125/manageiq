module MiqReportable
  # generate a ruport table from an array of db objects
  def self.records2table(records, only_columns)
    return Ruport::Data::Table.new if records.blank?

    data_records =  records.map do |r|
      r.get_attributes(only_columns)
    end

    data = data_records.map do |data_record|
      columns = data_record.keys
      [columns, data_record]
    end

    column_names = data.collect(&:first).flatten.uniq

    Ruport::Data::Table.new(:data         => data_records,
                            :column_names => column_names)
  end

  # generate a ruport table from an array of hashes where the keys are the column names
  def self.hashes2table(hashes, options)
    return Ruport::Data::Table.new if hashes.blank?

    data = hashes.inject([]) do |arr, h|
      nh = {}
      options[:only].each { |col| nh[col] = h[col] }
      arr << nh
    end

    data = data[0..options[:limit] - 1] if options[:limit] # apply limit
    Ruport::Data::Table.new(:data         => data,
                            :column_names => options[:only],
                            :filters      => options[:filters])
  end
end
