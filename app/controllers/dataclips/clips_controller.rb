module Dataclips
  class ClipsController < ApplicationController
    def show
      load_clips
      @clip_id = params[:clip_id]

      begin
        initialize_clip(@clip_id)
      rescue
        raise ActionController::RoutingError.new('Not Found')
      end

      @headers = localize_headers(@clip_id, @schema.keys)

      @clip = @klass.new params.slice(*@variables.keys)

      respond_to do |format|
        format.html do
          begin
            require_parameters
          rescue ActionController::ParameterMissing => e
            @error = e
            render :edit
          end
        end

        format.json do
          begin
            process_json(@clip, params[:page])
          rescue ActiveRecord::StatementInvalid => e
            render json: e.message, status: :unprocessable_entity
          end
        end
      end
    end

    def edit; end

    private

    def require_parameters
      @variables.keys.map(&:to_sym).each do |variable|
        params.require(variable)
      end
    end
  end
end
