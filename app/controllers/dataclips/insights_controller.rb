require "csv"

require_dependency File.join(Dataclips::Engine.root, "app/controllers/dataclips", "application_controller")

module Dataclips
  class InsightsController < ApplicationController
    include ActionController::Live

    def export
      setup_clip

      filename = "#{@insight.name.parameterize}.csv"

      response.headers['Content-Type']        = "text/csv"
      response.headers['Content-Disposition'] = "attachment; filename='#{filename}'"

      international_csv_options = {force_quotes: true}
      continental_csv_options   = {force_quotes: true, col_sep: ";"}

      locale = params[:locale] || I18n.default_locale
      csv_options = locale == "de" ? continental_csv_options : international_csv_options

      response.stream.write CSV.generate(csv_options) { |csv| csv << @headers.values}

      records = @clip.paginate(1)
      stream_records(records, csv_options, @time_zone)

      while next_page = records.next_page do
        records = @clip.paginate(next_page)
        stream_records(records, csv_options, @time_zone)
      end
    rescue IOError => e
      puts 'Connection closed'
    ensure
      response.stream.close
    end

    def show
      I18n.locale = params[:locale] || I18n.default_locale
      setup_clip

      respond_to do |format|
        format.html do
          @theme = params[:theme] || "default"
        end

        format.json do
          render_json_records(@clip, params[:page])
        end
      end
    end

    protected

    def stream_records(records, csv_options, time_zone)
      response.stream.write CSV.generate(csv_options) { |csv|
        records.each do |r|
          csv << r.values.map {|v| v.is_a?(Time) ? v.in_time_zone(time_zone).strftime(Time::DATE_FORMATS[:db]) : v }
        end
      }
    end

    def setup_clip
      @insight   = Insight.find_by_hash_id(params[:id]) or raise ActiveRecord::RecordNotFound
      @clip_id   = @insight.clip_id
      @time_zone = @insight.time_zone

      begin
        @klass     = "::Dataclips::#{@clip_id.gsub('/', '_').camelize}Clip".constantize
      rescue NameError
        Rails.logger.fatal("Dataclip: #{@clip_id} does not exist.")
        nil
      end

      @variables = @klass.variables
      @clip          = @klass.new @insight.params
      @clip.exclude!(@insight.excludes) if @insight.excludes.any?

      @schema = @clip.schema
      @headers   = localize_headers(@clip_id, @schema.keys)
    end
  end
end
