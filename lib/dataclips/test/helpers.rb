module Dataclips
  module Test
    module Helpers
      def sql_template(clip_name)
        template = File.read("#{Rails.root}/app/dataclips/#{clip_name}.sql")
        PgClip::Query.new(template)
      end
    end
  end
end
