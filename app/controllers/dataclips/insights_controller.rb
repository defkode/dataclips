require_dependency File.join(Dataclips::Engine.root, "app/controllers/dataclips", "application_controller")

module Dataclips
  class InsightsController < ApplicationController
    include ActionController::Live

    def export
      setup_clip

      response.headers['Content-Type']        = "text/csv"
      response.headers['Content-Disposition'] = "attachment; filename='#{@clip_id}.csv'"

      csv_options = {force_quotes: true}
      response.stream.write CSV.generate(csv_options) { |csv| csv << @headers.values}

      records = @clip.paginate(1)
      stream_records(records, csv_options)

      while next_page = records.next_page do
        records = @clip.paginate(next_page)
        stream_records(records, csv_options)
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
        format.html
        format.json { render_json_records(@clip, params[:page]) }
      end
    end

    protected

    def stream_records(records, csv_options)
      response.stream.write CSV.generate(csv_options) { |csv|
        records.each do |r|
          csv << r.values.map {|v| v.is_a?(Time) ? v.to_s(:db) : v }
        end
      }
    end

    def setup_clip
      @insight = Insight.find_by_hash_id(params[:id]) or raise ActiveRecord::RecordNotFound
      @clip_id = @insight.clip_id
      initialize_clip(@clip_id)
      @headers  = localize_headers(@clip_id, @schema.keys)
      @clip = @klass.new @insight.params
    end
  end
end
