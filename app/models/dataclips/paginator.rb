require 'will_paginate/array'

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
          when "text"
            type_caster = ActiveRecord::Type::String.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "integer"
            type_caster = ActiveRecord::Type::Integer.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "float"
            type_caster = ActiveRecord::Type::Float.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "datetime"
            type_caster = ActiveRecord::Type::DateTime.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "time"
            type_caster = ActiveRecord::Type::Time.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "date"
            type_caster = ActiveRecord::Type::Date.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
          when "boolean"
            type_caster = ActiveRecord::Type::Boolean.new
            type_caster.respond_to?(:cast) ?
              type_caster.cast(value) :
              type_caster.type_cast_from_database(value)
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
      offset = (page - 1) * per_page

      connection.execute <<-SQL
        WITH insight AS (#{query}), stats AS (
          SELECT
           #{page}                                 AS page,
           COUNT(*)                                AS total_count,
           CEIL(COUNT(*) / #{per_page}::numeric)   AS total_pages
          FROM insight
        )

        SELECT
          stats.*,
          row_to_json(insight) AS json
        FROM insight, stats
        OFFSET #{offset} LIMIT #{per_page};
      SQL
    end
  end
end
