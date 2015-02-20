module Dataclips
  class ClipsController < ApplicationController
    def show
      respond_to do |format|
        format.html do
          begin
            setup
          rescue ActionController::ParameterMissing => e
            @error = e
            render :edit
          end
        end

        format.json do
          begin
            setup
            process_json
          rescue ActiveRecord::StatementInvalid => e
            render json: e.message, status: :unprocessable_entity
          end
        end

        format.csv do
          begin
            setup
            process_csv
          rescue ActiveRecord::StatementInvalid
            head :unprocessable_entity
          end
        end
      end
    end

    def edit; end

    private

    def process_json
      records = @clip.paginate(params[:page] || 1)
      render json: {
        page:          records.current_page,
        total_pages:   records.total_pages,
        total_entries: records.total_entries,
        records:       records
      }
    end

    def process_csv
      self.response_body = Enumerator.new do |y|
        y << CSV.generate({col_sep: ";", encoding: "cp1250"}) do |csv|
          records = @clip.paginate(1)

          csv << records.first.keys

          records.each do |r|
            csv << r.values
          end

          while next_page = records.next_page do
            records = @clip.paginate(next_page)
            records.each do |r|
              csv << r.values
            end
          end
        end
      end
    end

    def setup
      Dataclips.load_clips
      load_clip_configuration
      # require_parameters
      setup_headers

      @clip = @klass.new params.slice(*@variables.keys)
    end

    def load_clip_configuration
      begin
        @clip_id   = params[:clip_id]
        @klass     = "Dataclips::Clip::#{@clip_id.camelize}".constantize
        @schema    = @klass.schema
        @variables = @klass.variables
      rescue
        raise ActionController::RoutingError.new('Not Found')
      end
    end

    def setup_headers
      @headers = @schema.keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{@clip_id}.#{key}", scope: "dataclips", default: key.to_s.humanize)
        memo
      end
    end

    def require_parameters
      @variables.keys.map(&:to_sym).each do |variable|
        params.require(variable)
      end
    end
  end
end
