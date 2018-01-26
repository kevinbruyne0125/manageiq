module ManagerRefresh
  class InventoryCollection
    module Index
      module Type
        class Data < ManagerRefresh::InventoryCollection::Index::Type::Base
          # Find value based on index_value
          #
          # @param index_value [String] a index_value of the InventoryObject we search in data
          def find(index_value)
            index[index_value]
          end
        end
      end
    end
  end
end
