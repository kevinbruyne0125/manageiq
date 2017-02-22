module ManagerRefresh
  class ApplicationRecordLite
    attr_reader :base_class_name, :id

    # ApplicationRecord is very bloaty in memory, so this class server for storing base_class and primary key
    # of the ApplicationRecord, which is just enough for filling up relationships
    def initialize(base_class_name, id)
      @base_class_name = base_class_name
      @id              = id
    end
  end
end
