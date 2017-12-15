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

      if @connection.present?
        ActiveRecord::Base.establish_connection Rails.configuration.database_configuration["dataclips_#{@connection}"]
      else
        ActiveRecord::Base.establish_connection Rails.configuration.database_configuration[Rails.env]
      end

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

          @theme = @clip.theme

          @sidebar = if params[:sidebar] && params[:sidebar] == "0"
            false
          else
            true
          end

          if @insight.basic_auth_credentials.present?
            request_http_basic_authentication unless authenticate_with_http_basic { |login, password| @insight.authenticate(login, password) }
          end
        end

        format.json do
          if @connection.present?
            ActiveRecord::Base.establish_connection Rails.configuration.database_configuration["dataclips_#{@connection}"]
          else
            ActiveRecord::Base.establish_connection Rails.configuration.database_configuration[Rails.env]
          end
          page = params[:page].present? ? params[:page].to_i : 1
          render_json_records(@query, @schema, page, @per_page)
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

    def localize_headers(clip_id, keys)
      keys.inject({}) do |memo, key|
        memo[key] = I18n.t("dataclips.#{clip_id}.schema.#{key}", default: key.to_s)
        memo
      end
    end

    def setup_clip
      @insight   = Insight.find_by_hash_id!(params[:id])

      @clip_id   = @insight.clip_id
      @time_zone = @insight.time_zone

      @clip      = Clip.new(@clip_id, @insight.schema)

      @schema     = @clip.schema
      @connection = @clip.connection
      @query      = @clip.query(@insight.params)
      @per_page   = @clip.per_page

      @headers   = localize_headers(@clip_id, @schema.keys)
    end

    def render_json_records(query, schema, page, per_page)
      paginator = Dataclips::Paginator.new(query, schema, per_page)

      pg_result = paginator.paginate(page)

      headers['X-Total-Count'] = pg_result.first['total_count']
      headers['X-Total-Pages'] = pg_result.first['total_pages']
      headers['X-Page']        = pg_result.first['page']

      render json: pg_result.map {|r| JSON.parse(r['json'])} # stream
    end
  end
end
