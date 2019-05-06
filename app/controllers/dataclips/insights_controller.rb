require "pg_clip"
# https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html

module Dataclips
  class InsightsController < ApplicationController
    before_action :find_and_authenticate_insight

    def show; end

    def data
      respond_to do |format|
        format.json do
          @insight.touch(:last_viewed_at)

          template  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}/query.sql")
          clip      = PgClip::Query.new(template)
          sql       = clip.query(@insight.params)

          paginator = PgClip::Paginator.new(sql, ActiveRecord::Base.connection)

          if per_page = @insight.per_page
            @result = paginator.execute_paginated_query(sql, page: params['page']&.to_i || 1, per_page: @insight.per_page)
          else
            @result = paginator.execute_query(sql)
          end

          render json: @result
        end
      end
    end

    private

    def find_and_authenticate_insight
      @insight = Dataclips::Insight.find_by!(hash_id: params[:id])

      if @insight.basic_auth_credentials.present?
        authenticate_or_request_with_http_basic { |login, password| @insight.authenticate(login, password) }
      end
    end
  end
end
