require "csv"

module Dataclips
  class ApplicationController < ActionController::Base
    include ActionView::Helpers::NumberHelper
    protected

    def initialize_clip(clip_id)
      @klass     = "Dataclips::#{clip_id.camelize}".constantize
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
      response.headers['Content-Type'] = 'text/event-stream'
      response.stream.write CSV.generate(force_quotes: true) { |csv| csv << headers.values}

      records = clip.paginate(1)

      response.stream.write CSV.generate(force_quotes: true) { |csv| records.each { |r| csv << r.values } }

      while next_page = records.next_page do
        records = clip.paginate(next_page)
        response.stream.write CSV.generate(force_quotes: true) { |csv| records.each { |r| csv << r.values } }
        sleep(1)
      end
    rescue IOError => e
      puts 'Connection closed'
    ensure
      response.stream.close
    end
  end
end
