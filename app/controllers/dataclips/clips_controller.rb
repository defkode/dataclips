module Dataclips
  class ClipsController < ApplicationController
    def show
      Dataclips.load_clips
      @clip_id = params[:clip_id]
      @clip_url = clip_path @clip_id

      klass = "Dataclips::Clip::#{@clip_id.camelize}".constantize

      @schema = klass.schema

      @headers = @schema.keys.inject({}) do |memo, key|
        memo[key] =  I18n.t("#{@clip_id}.#{key}", scope: "dataclips", default: key.to_s.humanize)
        memo
      end

      @variables = klass.variables.keys.map(&:to_sym)

      @variables.each do |variable|
        params.require(variable)
      end

      @clip = klass.new params.slice(*@variables)

      respond_to do |format|
        format.html do; end

        format.csv do
          self.response.headers["Content-Type"] ||= 'text/csv'
          self.response.headers["Content-Disposition"] = "attachment; filename=users.csv"
          self.response.headers["Content-Transfer-Encoding"] = "binary"
          self.response.headers["Last-Modified"] = Time.now.ctime.to_s

          self.response_body = Enumerator.new do |yielder|
            records = @clip.paginate(1)

            records.each do |record|
              yielder << CSV.generate_line(record.values)
            end
          end
        end

        format.json do
          records = @clip.paginate(params[:page] || 1)
          render json: {
            page:          records.current_page,
            total_pages:   records.total_pages,
            total_entries: records.total_entries,
            records:       records
          }
        end
      end
    end
  end
end
