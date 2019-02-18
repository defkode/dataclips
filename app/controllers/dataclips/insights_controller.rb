require "pg_clip"
# https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html

module Dataclips
  class InsightsController < ApplicationController

    def show
      @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
    end

    def data
      @insight = Dataclips::Insight.find_by_hash_id!(params[:id])

      template  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}.sql")
      clip      = PgClip::Query.new(template)

      sql       = clip.query(@insight.params)

      begin
        databases = ActiveRecord::Base.configurations
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(databases)

        spec = resolver.spec(@insight.connection.present? ? @insight.connection.to_sym : Rails.env.to_sym)

        pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)

        pool.with_connection do |connection|
          paginator = PgClip::Paginator.new(sql, connection)
          if per_page = @insight.per_page
            @result = paginator.execute_paginated_query(sql, page: params['page']&.to_i || 1, per_page: @insight.per_page)
          else
            @result = paginator.execute_query(sql)
          end
        end

        render json: @result
      rescue => ex
        Rails.logger.warn ex, ex.backtrace
        head :internal_server_error
      ensure
        pool.disconnect!
      end
    end
  end
end
