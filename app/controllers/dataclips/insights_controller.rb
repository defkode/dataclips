module Dataclips
  class InsightsController < ApplicationController
    include ActionController::Live

    def export
      setup_clip

      response.headers['Content-Type'] = 'text/csv'
      response.stream.write CSV.generate(force_quotes: true) { |csv| csv << @headers.values}

      records = @clip.paginate(1)

      response.stream.write CSV.generate(force_quotes: true) { |csv| records.each { |r| csv << r.values } }

      while next_page = records.next_page do
        records = @clip.paginate(next_page)
        response.stream.write CSV.generate(force_quotes: true) { |csv| records.each { |r| csv << r.values } }
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
        format.json { process_json(@clip, params[:page]) }
      end
    end

    protected

    def setup_clip
      @insight = Insight.find_by_hash_id(params[:id]) or raise ActiveRecord::RecordNotFound
      @clip_id = @insight.clip_id
      initialize_clip(@clip_id)
      @headers  = localize_headers(@clip_id, @schema.keys)
      @clip = @klass.new @insight.params
    end
  end
end
