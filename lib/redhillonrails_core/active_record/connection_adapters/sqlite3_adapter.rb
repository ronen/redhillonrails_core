module RedhillonrailsCore
  module ActiveRecord
    module ConnectionAdapters
      module Sqlite3Adapter

        def move_table(from, to, options = {}, &block) #:nodoc:
          copy_table(from, to, options, &block)
          drop_table(from, options)
        end

        def foreign_keys(table_name, name = nil)
          get_foreign_keys(table_name, name)
        end

        def reverse_foreign_keys(table_name, name = nil)
          get_foreign_keys(nil, name).select{|definition| definition.references_table_name == table_name}
        end

        private

        def get_foreign_keys(table_name = nil, name = nil)
          results = execute(<<-SQL, name)
            SELECT name, sql FROM sqlite_master
            WHERE type='table' #{table_name && %" AND name='#{table_name}' "}
          SQL

          re = %r[
            \bFOREIGN\s+KEY\s* \(\s*[`"](.+?)[`"]\s*\)
            \s*REFERENCES\s*[`"](.+?)[`"]\s*\((.+?)\)
            (\s+ON\s+UPDATE\s+(.+?))?
            (\s*ON\s+DELETE\s+(.+?))?
            \s*[,)]
          ]x

          foreign_keys = []
          results.each do |row|
            table_name = row["name"]
            row["sql"].scan(re).each do |column_names, references_table_name, references_column_names, d1, on_update, d2, on_delete|
              column_names = column_names.gsub('`', '').split(', ')

              references_column_names = references_column_names.gsub('`"', '').split(', ')
              on_update = on_update.downcase.gsub(' ', '_').to_sym if on_update
              on_delete = on_delete.downcase.gsub(' ', '_').to_sym if on_delete
              foreign_keys << ForeignKeyDefinition.new(nil,
                                                       table_name, column_names,
                                                       references_table_name, references_column_names,
                                                       on_update, on_delete)
            end
          end

          foreign_keys
        end

      end

    end
  end
end
