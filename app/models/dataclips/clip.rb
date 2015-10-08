require 'will_paginate/array'

module Dataclips
  class Clip
    include ActiveModel::Model

    class << self
      attr_accessor :template, :query

      def variables
        (@variables || {}).deep_symbolize_keys
      end

      def schema
        (@schema || {}).deep_symbolize_keys
      end

      def per_page
        @per_page || 1000
      end
    end

    def exclude!(fields = [])
      @excludes = fields.map(&:to_sym)
    end

    def schema
      excluded = @excludes || []
      self.class.schema.except(*@excludes)
    end

    def type_cast(attributes)
      schema.reduce({}) do |memo, (key, schema_key)|
        value = attributes[key]
        memo[key] = case schema_key[:type].to_sym
          when :text     then ActiveRecord::Type::String.new.type_cast_from_database(value)
          when :integer  then ActiveRecord::Type::Integer.new.type_cast_from_database(value)
          when :float    then ActiveRecord::Type::Float.new.type_cast_from_database(value)
          when :datetime then ActiveRecord::Type::DateTime.new.type_cast_from_database(value)
          when :time     then ActiveRecord::Type::Time.new.type_cast_from_database(value)
          when :date     then ActiveRecord::Type::Date.new.type_cast_from_database(value)
          when :boolean  then ActiveRecord::Type::Boolean.new.type_cast_from_database(value)
          else value
          end
        memo
      end
    end

    def id
      self.class.name.demodulize.underscore
    end

    def context
      return {} if invalid?
      self.class.variables.reduce({}) do |memo, (attr, options)|
        value = send(attr)

        memo[attr] = case options[:type]
          when "date"
            Date.parse(value).to_s
          else
            value.to_s
        end
        memo
      end.symbolize_keys
    end

    def query
      self.class.template % context
    end

    def paginate(page = 1)
      ActiveRecord::Base::transaction do
        WillPaginate::Collection.create(page, self.class.per_page) do |pager|
          results = ActiveRecord::Base.connection.execute <<-SQL
            BEGIN READ ONLY;
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
end
