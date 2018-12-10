module Dataclips
  class InsightsController < ApplicationController

    def show
      respond_to do |format|
        format.json do
          insight   = Dataclips::Insight.find_by_hash_id!(params[:id])

          template  = File.read("#{Rails.root}/app/dataclips/#{insight.clip_id}.sql")
          clip      = PgClip::Query.new(template)

          sql       = clip.query(insight.params)

          paginator = PgClip::Paginator.new(sql)
          if params[:page].present?
            render json: paginator.execute_paginated_query(sql, page: params['page']&.to_i || 1, per_page: 25_000)
          else
            render json: paginator.execute_query(sql)
          end
        end
      end

      format.html do
        @insight = Dataclips::Insight.find_by_hash_id!(params[:id])
        @schema  = File.read("#{Rails.root}/app/dataclips/#{@insight.clip_id}.yml")
      end
    end
  end
end
