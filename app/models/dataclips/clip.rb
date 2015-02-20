require 'will_paginate/array'

module Dataclips
  class Clip
    include ActiveModel::Model

    class << self
      attr_accessor :template, :query

      def variables
        @variables || {}
      end

      def schema
        @schema || {}
      end

      def per_page
        @per_page || 1000
      end
    end

    def type_cast(attributes)
      # https://github.com/rails/rails/blob/4-1-stable/activerecord/lib/active_record/connection_adapters/column.rb#L91-L109
      klass = ActiveRecord::ConnectionAdapters::Column

      attributes.each do |key, value|
        attributes[key] = case self.class.schema[key.to_sym]
          when :string, :text        then value
          when :integer              then klass.value_to_integer(value)
          when :float                then value.to_f
          when :decimal              then klass.value_to_decimal(value)
          when :datetime, :timestamp then klass.string_to_time(value)
          when :time                 then klass.string_to_dummy_time(value)
          when :date                 then klass.value_to_date(value)
          when :binary               then klass.binary_to_string(value)
          when :boolean              then klass.value_to_boolean(value)
          else value
          end
      end
    end

    def context
      as_json(except: ["errors", "validation_context"])
    end

    def query
      self.class.template % context.symbolize_keys
    end

    def paginate(page = 1)
      return unless valid?

      WillPaginate::Collection.create(page, self.class.per_page) do |pager|
        sql_with_total_entries = %{WITH _q AS (#{query}) SELECT COUNT(*) OVER () AS _total_entries, * FROM _q LIMIT #{pager.per_page} OFFSET #{pager.offset};}

        results = ActiveRecord::Base.connection.execute(sql_with_total_entries)

        if pager.total_entries.nil?
          pager.total_entries = results.none? ? 0 : results.first["_total_entries"].to_i
        end

        records = results.map do |record|
          type_cast record.except("_total_entries")
        end

        pager.replace records
      end
    end
  end
end
