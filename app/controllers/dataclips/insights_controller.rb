module Dataclips
  class InsightsController < ApplicationController
    def show
      load_clips

      @insight = Insight.find_by_hash_id(params[:id])
      @clip_id = @insight.clip_id
      initialize_clip(@clip_id)
      @headers  = localize_headers(@clip_id, @schema.keys)
      @clip = @klass.new @insight.params

      respond_to do |format|
        format.html
        format.json { process_json(@clip, params[:page]) }
        format.csv  { process_csv(@clip, @headers) }
      end
    end
  end
end
