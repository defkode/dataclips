module Dataclips
  class Paginator
    attr_accessor :query, :schema, :per_page

    def initialize(query, schema, per_page = 1000)
      @query    = query
      @schema   = schema.symbolize_keys
      @per_page = per_page
    end

    def connection
      ActiveRecord::Base.connection
    end

    def type_cast(attributes)
      schema.reduce({}) do |memo, (key, schema_key)|
        value = attributes[key]
        memo[key] = case schema_key["type"]
          when "text"     then ActiveRecord::Type::String.new.type_cast_from_database(value)
          when "integer"  then ActiveRecord::Type::Integer.new.type_cast_from_database(value)
          when "float"    then ActiveRecord::Type::Float.new.type_cast_from_database(value)
          when "datetime" then ActiveRecord::Type::DateTime.new.type_cast_from_database(value)
          when "time"     then ActiveRecord::Type::Time.new.type_cast_from_database(value)
          when "date"     then ActiveRecord::Type::Date.new.type_cast_from_database(value)
          when "boolean"  then ActiveRecord::Type::Boolean.new.type_cast_from_database(value)
          else value
          end
        memo
      end
    end

    # without pager
    def records
      results = connection.execute(query)
      records = results.map do |record|
        type_cast record.symbolize_keys
      end
    end

    def paginate(page = 1)
      WillPaginate::Collection.create(page, per_page) do |pager|
        results = connection.execute <<-SQL
          WITH insight AS (#{query})
            SELECT
              COUNT(*) OVER () AS _total_entries_count,
              *
            FROM insight
            LIMIT #{pager.per_page} OFFSET #{pager.offset};
        SQL

        if pager.total_entries.nil?
          pager.total_entries = results.none? ? 0 : results.first["_total_entries_count"].to_i
        end

        records = results.map do |record|
          type_cast record.except("_total_entries_count").symbolize_keys
        end

        pager.replace records
      end
    end
  end
end
