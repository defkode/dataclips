module Dataclips
  class ApplicationController < ActionController::Base
    include ActionView::Helpers::NumberHelper
    protected

    def initialize_clip(clip_id)
      begin
        @klass     = "Dataclips::#{clip_id.camelize}".constantize
        @schema    = @klass.schema
        @variables = @klass.variables
      rescue NameError
        Rails.logger.fatal("Dataclip: #{clip_id} does not exist.")
        nil
      end
    end

    def localize_headers(clip_id, keys)
      keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{clip_id}.schema.#{key}", scope: "dataclips", default: key.to_s)
        memo
      end
    end

    def render_json_records(clip, page = 1)
      page = params[:page] || 1
      records = clip.paginate(page)

      render json: {
        page:          records.current_page,
        total_pages:   records.total_pages,
        total_entries: records.total_entries,
        records:       records
      }
    end
  end
end
