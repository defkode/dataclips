module Dataclips
  class SQLQuery
    attr_accessor :configuration, :schema, :template

    def initialize(sqlfile)
      @template       = parse_template(sqlfile)
      @configuration  = parse_configuration(sqlfile)
    end

    def schema
      _schema = {}
      (configuration["schema"] || {}).each do |attribute, options|
        _schema[attribute] = options.reverse_merge({grid: true, filter: true})
      end
      _schema
    end

    def variables
      configuration["variables"] || {}
    end

    def options
      @configuration["options"] || {}
    end

    private

    def parse_configuration(sqlfile)
      if matches = sqlfile.match(/\/\*\s+(.+)\s+\*\/\s+-- QUERY/m)
        YAML.load matches[1]
      else
        {}
      end
    end

    def parse_template(sqlfile)
      sqlfile.match(/-- QUERY(.+)/m)[1]
    end
  end
end
