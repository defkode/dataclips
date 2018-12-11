module Dataclips
  class InsightsController < ApplicationController

    def show
      with_connection(Rails.env) do
        @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
      end
    end

    def data
      with_connection(Rails.env) do
        @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
      end

      template  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}.sql")
      clip      = PgClip::Query.new(template)

      sql       = clip.query(@insight.params)

      connection_name = @insight.connection.present? ? "dataclips_#{@insight.connection}" : Rails.env
      with_connection(connection_name) do
        paginator = PgClip::Paginator.new(sql, ActiveRecord::Base.connection)
        if per_page = @insight.per_page
          render json: paginator.execute_paginated_query(sql, page: params['page']&.to_i || 1, per_page: @insight.per_page)
        else
          render json: paginator.execute_query(sql)
        end
      end
    end

    private

    def with_connection(connection_name)
      ActiveRecord::Base.establish_connection Rails.configuration.database_configuration[connection_name]
      yield
    ensure
      ActiveRecord::Base.establish_connection Rails.configuration.database_configuration[Rails.env]
    end
  end
end
