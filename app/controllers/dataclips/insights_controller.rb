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
          page      = params['page']&.to_i
          per_page  = @insight.per_page

          if Dataclips::Engine.config.multiple_db
            # MULTIPLE DB - conenction switching
            begin
              databases = ActiveRecord::Base.configurations

              resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(databases)
              spec     = resolver.spec(@insight.connection.present? ? @insight.connection.to_sym : Rails.env.to_sym)
              pool     = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)

              pool.with_connection do |conn|
                render json: retrieve_results(query: query, page: page, per_page: per_page, connection: conn)
              end
            rescue => ex
              raise ex
              Rails.logger.warn ex, ex.backtrace
              head :internal_server_error
            ensure
              pool.disconnect!
            end
          else
            # SINGLE DB (reports in the same DB as insights)
            render json: retrieve_results(query: query, page: page, per_page: per_page)
          end
        end
      end
    end

    private

    def retrieve_results(query: , page: 1, per_page: nil, connection: ActiveRecord::Base.connection)
      paginator = PgClip::Paginator.new(query, connection)

      if per_page
        paginator.execute_paginated_query(query, page: page, per_page: per_page)
      else
        paginator.execute_query(query)
      end
    end
  end
end
