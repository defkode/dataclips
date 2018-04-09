require "liquid"

module DataclipsFilters
  def quote_literals(input)
    input.map do |item|
      item.is_a?(String) ? "'#{item}'" : item
    end
  end
end

Liquid::Template.register_filter(DataclipsFilters)

module Dataclips
  class Clip
    attr_accessor :clip_id, :template, :params, :schema, :name

    def initialize(clip_id, schema = nil)
      @clip_id   = clip_id
      @template  = load_template

      load_config(schema)
    end

    def per_page
      @per_page
    end

    def connection
      if @connection
        connection_name = "dataclips_#{@connection}_#{Rails.env}".to_sym # dataclips_stats_production
        ActiveRecord::Base.establish_connection(connection_name).connection
      else
        ActiveRecord::Base.connection
      end
    end

    def theme
      @theme
    end

    def load_config(schema)
      config_file = Dir.chdir(Dataclips::Engine.config.path) do
        schema.present? ? File.read("#{clip_id}.#{schema}.yml") : File.read("#{clip_id}.yml")
      end

      config_yaml = YAML.load(config_file)

      @schema = (config_yaml["schema"] || {}).reduce({}) do |schema, (attribute, options)|
        schema[attribute] = options.reverse_merge({"grid" => true, "filter" => true})
        schema
      end

      @per_page   = config_yaml["per_page"] || 1000
      @connection = config_yaml["connection"]
      @theme      = config_yaml["theme"] || 'default'
      @name       = config_yaml["name"]
    end

    def load_template
      Dir.chdir(Dataclips::Engine.config.path) do
        Liquid::Template.parse File.read("#{clip_id}.sql")
      end
    end

    def query(params = {})
      template.render(params.with_indifferent_access)
    end

    def paginate(page = 1)
      WillPaginate::Collection.create(page, self.class.per_page) do |pager|
        results = self.class.connection.execute <<-SQL
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
