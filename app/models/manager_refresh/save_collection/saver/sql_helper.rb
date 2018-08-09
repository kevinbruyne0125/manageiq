module ManagerRefresh::SaveCollection
  module Saver
    module SqlHelper
      # TODO(lsmola) all below methods should be rewritten to arel, but we need to first extend arel to be able to do
      # this

      # Builds ON CONFLICT UPDATE updating branch for one column identified by the passed key
      #
      # @param key [Symbol] key that is column name
      # @return [String] SQL clause for upserting one column
      def build_insert_set_cols(key)
        "#{quote_column_name(key)} = EXCLUDED.#{quote_column_name(key)}"
      end

      # @param all_attribute_keys [Array<Symbol>] Array of all columns we will be saving into each table row
      # @param hashes [Array<Hash>] data used for building a batch insert sql query
      # @param mode [Symbol] Mode for saving, allowed values are [:full, :partial], :full is when we save all
      #        columns of a row, :partial is when we save only few columns, so a partial row.
      # @param on_conflict [Symbol, NilClass] defines behavior on conflict with unique index constraint, allowed values
      #        are :do_update, :do_nothing, nil
      def build_insert_query(all_attribute_keys, hashes, on_conflict: nil, mode:, column_name: nil)
        _log.debug("Building insert query for #{inventory_collection} of size #{inventory_collection.size}...")

        # Cache the connection for the batch
        connection = get_connection

        ignore_cols = if mode == :partial
                        [:timestamp]
                      elsif mode == :full
                        []
                      end

        # Make sure we don't send a primary_key for INSERT in any form, it could break PG sequencer
        all_attribute_keys_array = all_attribute_keys.to_a - [primary_key.to_s, primary_key.to_sym] - ignore_cols
        values                   = hashes.map do |hash|
          "(#{all_attribute_keys_array.map { |x| quote(connection, hash[x], x) }.join(",")})"
        end.join(",")
        col_names = all_attribute_keys_array.map { |x| quote_column_name(x) }.join(",")

        insert_query = %{
          INSERT INTO #{table_name} (#{col_names})
            VALUES
              #{values}
        }

        if inventory_collection.parallel_safe?
          if on_conflict == :do_nothing
            insert_query += %{
              ON CONFLICT DO NOTHING
            }
          elsif on_conflict == :do_update
            index_where_condition = unique_index_for(unique_index_keys).where
            where_to_sql = index_where_condition ? "WHERE #{index_where_condition}" : ""

            insert_query += %{
              ON CONFLICT (#{unique_index_columns.map { |x| quote_column_name(x) }.join(",")}) #{where_to_sql}
                DO
                  UPDATE
            }

            ignore_cols += if mode == :partial
                            [:timestamps, :timestamps_max]
                          elsif mode == :full
                            []
                          end
            ignore_cols += [:created_on, :created_at] # Lets not change created_at for the update clause

            # TODO(lsmola) do we want to exclude the ems_id from the UPDATE clause? Otherwise it might be difficult to change
            # the ems_id as a cross manager migration, since ems_id should be there as part of the insert. The attempt of
            # changing ems_id could lead to putting it back by a refresh.
            # TODO(lsmola) should we add :deleted => false to the update clause? That should handle a reconnect, without a
            # a need to list :deleted anywhere in the parser. We just need to check that a model has the :deleted attribute

            # This conditional will avoid rewriting new data by old data. But we want it only when remote_data_timestamp is a
            # part of the data, since for the fake records, we just want to update ems_ref.
            if mode == :full
              insert_query += %{
                SET #{(all_attribute_keys_array - ignore_cols).map { |key| build_insert_set_cols(key) }.join(", ")}
              }
              if supports_remote_data_timestamp?(all_attribute_keys)
                insert_query += %{
                  , timestamps = '{}', timestamps_max = NULL

                  WHERE EXCLUDED.timestamp IS NULL OR (
                    (#{table_name}.timestamp IS NULL OR EXCLUDED.timestamp > #{table_name}.timestamp) AND
                    (#{table_name}.timestamps_max IS NULL OR EXCLUDED.timestamp >= #{table_name}.timestamps_max)
                  )
                }
              end
            elsif mode == :partial
              raise "Column name not defined for #{hashes}" unless column_name

              insert_query += %{
                 SET #{(all_attribute_keys_array - ignore_cols).map { |key| build_insert_set_cols(key) }.join(", ")}
              }
              if supports_max_timestamp?
                # TODO(lsmola) we should have EXCLUDED.timestamp > #{table_name}.timestamp, but if skeletal precreate
                # creates the row, it sets timestamp. Should we combine it with complete => true only? We probably need
                # to set the timestamp, otherwise we can't touch it in the update clause. Maybe we coud set it as
                # timestamps_max?

                insert_query += %{
                  , timestamps = #{table_name}.timestamps || ('{"#{column_name}": "' || EXCLUDED.timestamps_max::timestamp || '"}')::jsonb
                  , timestamps_max = greatest(#{table_name}.timestamps_max::timestamp, EXCLUDED.timestamps_max::timestamp)
                  WHERE EXCLUDED.timestamps_max IS NULL OR (
                    (#{table_name}.timestamp IS NULL OR EXCLUDED.timestamps_max > #{table_name}.timestamp) AND (
                      (#{table_name}.timestamps->>'#{column_name}')::timestamp IS NULL OR
                      EXCLUDED.timestamps_max::timestamp > (#{table_name}.timestamps->>'#{column_name}')::timestamp
                    )
                  )
                }
              end
            end
          end
        end

        insert_query += %{
          RETURNING "id",#{unique_index_columns.map { |x| quote_column_name(x) }.join(",")}
        }

        _log.debug("Building insert query for #{inventory_collection} of size #{inventory_collection.size}...Complete")

        insert_query
      end

      # Builds update clause for one column identified by the passed key
      #
      # @param key [Symbol] key that is column name
      # @return [String] SQL clause for updating one column
      def build_update_set_cols(key)
        "#{quote_column_name(key)} = updated_values.#{quote_column_name(key)}"
      end

      # Returns quoted column name
      # @param key [Symbol] key that is column name
      # @returns [String] quoted column name
      def quote_column_name(key)
        get_connection.quote_column_name(key)
      end

      # @return [ActiveRecord::ConnectionAdapters::AbstractAdapter] ActiveRecord connection
      def get_connection
        ActiveRecord::Base.connection
      end

      # Build batch update query
      #
      # @param all_attribute_keys [Array<Symbol>] Array of all columns we will be saving into each table row
      # @param hashes [Array<Hash>] data used for building a batch update sql query
      def build_update_query(all_attribute_keys, hashes)
        _log.debug("Building update query for #{inventory_collection} of size #{inventory_collection.size}...")
        # Cache the connection for the batch
        connection = get_connection

        # We want to ignore type and create timestamps when updating
        all_attribute_keys_array = all_attribute_keys.to_a.delete_if { |x| %i(type created_at created_on).include?(x) }
        all_attribute_keys_array << :id

        values = hashes.map! do |hash|
          "(#{all_attribute_keys_array.map { |x| quote(connection, hash[x], x, true) }.join(",")})"
        end.join(",")

        update_query = %{
          UPDATE #{table_name}
            SET
              #{all_attribute_keys_array.map { |key| build_update_set_cols(key) }.join(",")}
        }

        if supports_remote_data_timestamp?(all_attribute_keys)
          # Full row update will reset the partial update timestamps
          update_query += %{
             , timestamps = '{}', timestamps_max = NULL
          }
        end

        update_query += %{
          FROM (
            VALUES
              #{values}
          ) AS updated_values (#{all_attribute_keys_array.map { |x| quote_column_name(x) }.join(",")})
          WHERE updated_values.id = #{table_name}.id
        }

        # TODO(lsmola) do we want to exclude the ems_id from the UPDATE clause? Otherwise it might be difficult to change
        # the ems_id as a cross manager migration, since ems_id should be there as part of the insert. The attempt of
        # changing ems_id could lead to putting it back by a refresh.

        # This conditional will avoid rewriting new data by old data. But we want it only when remote_data_timestamp is a
        # part of the data, since for the fake records, we just want to update ems_ref.
        if supports_remote_data_timestamp?(all_attribute_keys)
          update_query += %{
            AND (
              updated_values.timestamp IS NULL OR (
                (#{table_name}.timestamp IS NULL OR updated_values.timestamp > #{table_name}.timestamp) AND
                (#{table_name}.timestamps_max IS NULL OR updated_values.timestamp >= #{table_name}.timestamps_max)
              )
            )
          }
        end

        _log.debug("Building update query for #{inventory_collection} of size #{inventory_collection.size}...Complete")

        update_query
      end

      # Builds a multiselection conditions like (table1.a = a1 AND table2.b = b1) OR (table1.a = a2 AND table2.b = b2)
      #
      # @param hashes [Array<Hash>] data we want to use for the query
      # @return [String] condition usable in .where of an ActiveRecord relation
      def build_multi_selection_query(hashes)
        inventory_collection.build_multi_selection_condition(hashes, unique_index_columns)
      end

      # Quotes a value. For update query, the value also needs to be explicitly casted, which we can do by
      # type_cast_for_pg param set to true.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] ActiveRecord connection
      # @param value [Object] value we want to quote
      # @param name [Symbol] name of the column
      # @param type_cast_for_pg [Boolean] true if we want to also cast the quoted value
      # @return [String] quoted and based on type_cast_for_pg param also casted value
      def quote(connection, value, name = nil, type_cast_for_pg = nil)
        # TODO(lsmola) needed only because UPDATE FROM VALUES needs a specific PG typecasting, remove when fixed in PG
        if type_cast_for_pg
          quote_and_pg_type_cast(connection, value, name)
        else
          connection.quote(value)
        end
      rescue TypeError => e
        _log.error("Can't quote value: #{value}, of :#{name} and #{inventory_collection}")
        raise e
      end

      # Quotes and type casts the value.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] ActiveRecord connection
      # @param value [Object] value we want to quote
      # @param name [Symbol] name of the column
      # @return [String] quoted and casted value
      def quote_and_pg_type_cast(connection, value, name)
        pg_type_cast(
          connection.quote(value),
          pg_types[name]
        )
      end

      # Returns a type casted value in format needed by PostgreSQL
      #
      # @param value [Object] value we want to quote
      # @param sql_type [String] PostgreSQL column type
      # @return [String] type casted value in format needed by PostgreSQL
      def pg_type_cast(value, sql_type)
        if sql_type.nil?
          value
        else
          "#{value}::#{sql_type}"
        end
      end
    end
  end
end
