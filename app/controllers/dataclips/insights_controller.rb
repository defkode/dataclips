require_dependency File.join(Dataclips::Engine.root, "app/controllers/dataclips", "application_controller")

module Dataclips
  class InsightsController < ApplicationController

    def show
      I18n.locale = params[:locale] || I18n.default_locale

      # SETUP
      @insight   = Insight.find_by_hash_id!(params[:id])

      @clip      = Clip.new(@insight.clip_id, @insight.schema)

      @schema    = @clip.schema
      @query     = @clip.query(@insight.params)
      @per_page  = @clip.per_page

      respond_to do |format|
        format.html do
          @insight.touch(:last_viewed_at)

          @theme = params[:theme] || "default"
          if @insight.basic_auth_credentials.present?
            request_http_basic_authentication unless authenticate_with_http_basic { |login, password| @insight.authenticate(login, password) }
          end
        end

        format.json do
          paginator = Dataclips::Paginator.new(@query, @schema, @per_page)
          records = paginator.paginate(params[:page] || 1)

          render json: {
            page:                records.current_page,
            total_pages:         records.total_pages,
            total_entries_count: records.total_entries,
            records:             records
          }
        end
      end
    end
  end
end
