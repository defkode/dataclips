module Dataclips
  module Test
    module Helpers
      def sql_template(clip_name)
        template = File.read("#{Rails.root}/app/dataclips/#{clip_name}.sql")
        PgClip::Query.new(template)
      end

      def dataclips_records(sql)
        paginator = PgClip::Paginator.new(sql, ActiveRecord::Base.connection)
        paginator.records
      end
    end
  end
end
