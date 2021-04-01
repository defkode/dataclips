require "pg_clip"

module Dataclips
  class QueryTemplate
    class << self
      def all
        Dir.glob("#{Dataclips::Engine.config.path}/**/*/query.sql").map do |query_path|
          query_path.sub(Dataclips::Engine.config.path, "BASE_DIR").match(/BASE_DIR\/(.+)\/query.sql/)[1]
        end.sort
      end
    end

    attr_reader :template

    def initialize(clip_id)
      raise ArgumentError.new("Query: #{clip_id} not found in #{Dataclips::Engine.config.path}") if self.class.all.exclude?(clip_id)

      @clip_id = clip_id
      @template = read_template
    end

    def execute(params: {}, connection: ActiveRecord::Base.connection)
      connection.execute(to_sql(params)).to_a
    end

    def to_sql(params)
      clip = PgClip::Query.new(@template) # liquid template
      sql  = clip.query(params) # template filled with dynamic params
    end

    private

    def read_template
      File.read(File.join(Dataclips::Engine.config.path, @clip_id, "query.sql"))
    end
  end
end
