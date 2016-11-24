module Dataclips
  class Clip
    attr_accessor :clip_id, :template, :params, :schema

    def initialize(clip_id)
      @clip_id   = clip_id
      @template  = load_template
      @schema    = load_schema
    end

    def load_schema
      schema_file = Dir.chdir(Dataclips::Engine.config.path) do
        File.read("#{clip_id}.yml")
      end

      schema = {}
      (YAML.load(schema_file) || {}).each do |attribute, options|
        schema[attribute] = options.reverse_merge({"grid" => true, "filter" => true})
      end
      schema
    end

    def load_template
      Dir.chdir(Dataclips::Engine.config.path) do
        File.read("#{clip_id}.sql")
      end
    end

    def query(params = {})
      template % params.deep_symbolize_keys
    end
  end
end
