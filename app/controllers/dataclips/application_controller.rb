module Dataclips
  class ApplicationController < ActionController::Base
    include ActionView::Helpers::NumberHelper
    protected

    def load_clips
      Dataclips.load_clips if Rails.env.development?
    end

    def initialize_clip(clip_id)
      @klass     = "Dataclips::Clip::#{clip_id.camelize}".constantize
      @schema    = @klass.schema
      @variables = @klass.variables
    end

    def localize_headers(clip_id, keys)
      keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{clip_id}.#{key}", scope: "dataclips", default: key.to_s.humanize)
        memo
      end
    end

    def process_json(clip, page = 1)
      records = clip.paginate(params[:page] || 1)
      render json: {
        page:          records.current_page,
        total_pages:   records.total_pages,
        total_entries: records.total_entries,
        records:       records
      }
    end

    def process_csv(clip, headers)
      self.response_body = Enumerator.new do |y|
        y << CSV.generate(force_quotes: true) do |csv|
          records = clip.paginate(1)

          csv << headers.values

          records.each do |r|
            csv << r.values
          end

          while next_page = records.next_page do
            records = clip.paginate(next_page)
            records.each do |r|
              csv << r.values
            end
          end
        end
      end
    end
  end
end
