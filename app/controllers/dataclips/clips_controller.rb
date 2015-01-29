module Dataclips
  class ClipsController < ApplicationController
    def show
      Dataclips.load_clips
      @clip_id = params[:clip_id]
      klass = "Dataclips::Clip::#{@clip_id.camelize}".constantize

      @schema = klass.schema

      @headers = @schema.keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{@clip_id}.#{key}", scope: "dataclips", default: key.to_s.humanize)
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
          self.response_body = Enumerator.new do |y|
            xxx = CSV.generate({col_sep: ";", encoding: "cp1250"}) do |csv|
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

            y << xxx
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
