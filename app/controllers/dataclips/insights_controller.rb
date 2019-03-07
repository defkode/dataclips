require "pg_clip"
# https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html

module Dataclips
  class InsightsController < ApplicationController
    def show
      @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
      @insight.touch(:last_viewed_at)
    end

    def data
      @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
      @insight.touch(:last_viewed_at)

      template  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}.sql")
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
