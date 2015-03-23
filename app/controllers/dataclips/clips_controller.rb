module Dataclips
  class ClipsController < ApplicationController
    def show
      @clip_id = params[:clip_id]

      if initialize_clip(@clip_id)
        @headers = localize_headers(@clip_id, @schema.keys)

        @clip = @klass.new params.slice(*@variables.keys)

        respond_to do |format|
          format.html do
            begin
              require_parameters
            rescue ActionController::ParameterMissing => e
              @error = e
              render :require_variables
            end
          end

          format.json do
            begin
              require_parameters
              render_json_records(@clip, params[:page])
            rescue ActiveRecord::StatementInvalid => e
              render json: e.message, status: :unprocessable_entity
            end
          end
        end
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end

    private

    def require_parameters
      @variables.keys.map(&:to_sym).each do |variable|
        params.require(variable)
      end
    end
  end
end
