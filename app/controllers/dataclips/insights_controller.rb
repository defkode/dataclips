require "pg_clip"
# https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html

module Dataclips
  class InsightsController < ApplicationController

    def show
      @insight = Dataclips::Insight.shared.find_by!(hash_id: params[:id])
      authenticate_insight(@insight)
    end

    def data
      @insight = Dataclips::Insight.shared.find_by!(hash_id: params[:id])
      authenticate_insight(@insight)
      @insight.touch(:last_viewed_at)

      template  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}/query.sql")
      clip      = PgClip::Query.new(template)
      sql       = clip.query(@insight.params)

      if Dataclips::Engine.config.multiple_db
        # MULTIPLE DB - conenction switching
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
          raise ex
          Rails.logger.warn ex, ex.backtrace
          head :internal_server_error
        ensure
          pool.disconnect!
        end
      else
        # SINGLE DB (reports in the same DB as insights)
        paginator = PgClip::Paginator.new(sql, ActiveRecord::Base.connection)

        if per_page = @insight.per_page
          @result = paginator.execute_paginated_query(sql, page: params['page']&.to_i || 1, per_page: @insight.per_page)
        else
          @result = paginator.execute_query(sql)
        end

        render json: @result
      end
    end

    private

    def authenticate_insight(insight)
      if insight.basic_auth_credentials.present?
        if authenticate_with_http_basic { |login, password| insight.authenticate(login, password) }
        else
          request_http_basic_authentication
        end
      end
    end
  end
end
