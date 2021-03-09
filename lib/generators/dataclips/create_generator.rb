module Dataclips
  class CreateGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_query_file
      folder_path = File.join(Dataclips::Engine.config.path, name)

      if ActiveRecord::Base.connection.table_exists?(name)
        table_name = name
        columns = ActiveRecord::Base.connection.columns(table_name)

        template "query.sql", File.join(folder_path, "query.sql"), {
          table_name: table_name,
          column_names: columns.map(&:name)
        }

        schema = columns.inject({}) do |obj, column|
          obj[column.name] = {
            type: case column.type
            when :integer, :bigint, :decimal, :float then "number"
            when :date then "date"
            when :datetime, :timestamp then "datetime"
            when :time then "time"
            when :duration then "duration"
            when :boolean then "boolean"
            else
              "text"
            end
          }
          obj
        end

        template "schema.json", File.join(folder_path, "schema.json"), {
          schema: schema
        }
      else
        template "query.sql", File.join(folder_path, "query.sql"), {
          table_name: "table_name",
          column_names: %w(id name active created_at updated_at)
        }

        template "schema.json", File.join(folder_path, "schema.json"), {
          schema: {
            id:         {type: :number},
            name:       {type: :text},
            active:     {type: :boolean},
            created_at: {type: :datetime},
            updated_at: {type: :datetime}
          }
        }
      end
    end
  end
end
