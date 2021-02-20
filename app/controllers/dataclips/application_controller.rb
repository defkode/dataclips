module Dataclips
  class ApplicationController < ActionController::Base
    include ::Dataclips::ApplicationHelper

    private

    def find_and_authenticate_insight
      @insight = Dataclips::Insight.shared.find_by!(hash_id: params[:id])
    end
  end
end
