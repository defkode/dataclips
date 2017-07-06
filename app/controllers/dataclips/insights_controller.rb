require "csv"

require_dependency File.join(Dataclips::Engine.root, "app/controllers/dataclips", "application_controller")

module Dataclips
  class InsightsController < ApplicationController
    include ActionController::Live

    def export
      setup_clip

      filename = if params[:filename].present?
        params[:filename]
      else
        @insight.name.present? ? @insight.name : @insight.clip_id.parameterize
      end

      response.headers['Content-Type']        = "text/csv"
      response.headers['Content-Disposition'] = "attachment; filename=#{filename}.csv"

      international_csv_options = {force_quotes: true}
      continental_csv_options   = {force_quotes: true, col_sep: ";"}

      locale = params[:locale] || I18n.default_locale
      csv_options = locale == "de" ? continental_csv_options : international_csv_options

      response.stream.write CSV.generate(csv_options) { |csv| csv << @headers.values}

      paginator = Dataclips::Paginator.new(@query, @schema)

      records = paginator.paginate(1)
      stream_records(records, csv_options, @time_zone)

      while next_page = records.next_page do
        records = paginator.paginate(next_page)
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
          @insight.touch(:last_viewed_at)

          @theme = params[:theme] || "default"
          @sidebar = params[:sidebar] == "1"

          if @insight.basic_auth_credentials.present?
            request_http_basic_authentication unless authenticate_with_http_basic { |login, password| @insight.authenticate(login, password) }
          end
        end

        format.json do
          render_json_records(@query, @schema, params[:page], @per_page)
        end
      end
    end

    def index
    end

    protected

    def stream_records(records, csv_options, time_zone)
      response.stream.write CSV.generate(csv_options) { |csv|
        records.each do |r|
          csv << r.values.map {|v| v.is_a?(Time) ? v.in_time_zone(time_zone).strftime(Time::DATE_FORMATS[:db]) : v }
        end
      }
    end

    def localize_headers(clip_id, keys)
      keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{clip_id}.schema.#{key}", scope: "dataclips", default: key.to_s)
        memo
      end
    end

    def setup_clip
      @insight   = Insight.find_by_hash_id!(params[:id])

      @clip_id   = @insight.clip_id
      @time_zone = @insight.time_zone

      @clip      = Clip.new(@clip_id, @insight.schema) 

      @schema    = @clip.schema
      @query     = @clip.query(@insight.params)
      @per_page  = @clip.per_page

      @headers   = localize_headers(@clip_id, @schema.keys)
    end

    def render_json_records(query, schema, page, per_page)
      paginator = Dataclips::Paginator.new(query, schema, per_page)
      records = paginator.paginate(page || 1)

      render json: {
        page:                records.current_page,
        total_pages:         records.total_pages,
        total_entries_count: records.total_entries,
        records:             records
      }
    end
  end
end
