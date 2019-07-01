# This monkey patches rails to support proper joins
# current PR: https://github.com/rails/rails/pull/36531
module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module SchemaStatements
        def columns_for_distinct(columns, orders) #:nodoc:
          order_columns = orders.reject(&:blank?).map { |s|
              # Convert Arel node to string
              unless s.is_a?(String)
                if s.respond_to?(:to_sql)
                  s = s.to_sql
                else # for Arel::Nodes::Attribute
                  engine = Arel::Table.engine
                  collector = Arel::Collectors::SQLString.new
                  collector = engine.connection.visitor.accept s, collector
                  s = collector.value
                end
              end
              # Remove any ASC/DESC modifiers
              s.gsub(/\s+(?:ASC|DESC)\b/i, "")
               .gsub(/\s+NULLS\s+(?:FIRST|LAST)\b/i, "")
            }.reject(&:blank?).map.with_index { |column, i| "#{column} AS alias_#{i}" }

          (order_columns << super).join(", ")
        end
      end
    end
  end
end
