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

    def type_cast(attributes)
      # https://github.com/rails/rails/blob/4-1-stable/activerecord/lib/active_record/connection_adapters/column.rb#L91-L109
      klass = ActiveRecord::ConnectionAdapters::Column

      attributes.reduce({}) do |memo, (key, value)|
        if schema_key = self.class.schema[key]
          memo[key] = case schema_key[:type].to_sym
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
        memo
      end

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
      WillPaginate::Collection.create(page, self.class.per_page) do |pager|
        sql_with_total_entries = %{WITH _q AS (#{query}) SELECT COUNT(*) OVER () AS _total_entries, * FROM _q LIMIT #{pager.per_page} OFFSET #{pager.offset};}

        results = ActiveRecord::Base.connection.execute(sql_with_total_entries)

        if pager.total_entries.nil?
          pager.total_entries = results.none? ? 0 : results.first["_total_entries"].to_i
        end

        records = results.map do |record|
          type_cast record.except("_total_entries").symbolize_keys
        end

        pager.replace records
      end
    end
  end
end
