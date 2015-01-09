module Dataclips
  class SQLQuery
    attr_accessor :configuration, :schema, :template

    def initialize(sqlfile)
      @template       = parse_template(sqlfile)
      @schema         = parse_schema(sqlfile)
      @configuration  = parse_configuration(sqlfile)
    end

    def variables
      configuration["variables"] || {}
    end

    def options
      @configuration["options"] || {}
    end

    private

    def parse_configuration(sqlfile)
      if matches = sqlfile.match(/\/\*\s+(.+)\s+\*\/\s+SELECT/m)
        YAML.load matches[1]
      else
        {}
      end
    end

    def parse_template(sqlfile)
      sqlfile.match(/(SELECT.+)/m)[1]
    end

    def parse_schema(sqlfile)
      columns = sqlfile.match(/SELECT(.+)FROM.+/m)[1] # catch everything between SELECT and FROM statements
      columns.scan(/.+ AS (\w+),?(\s+\/\*\s+(\w+)\s+\*\/)?$/).inject({}) do |m, (name, comment, type)|
        m[name.to_sym] = (type || "string").to_sym
        m
      end
    end
  end
end
