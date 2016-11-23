module Dataclips
  class ApplicationController < ActionController::Base
    include ActionView::Helpers::NumberHelper
    protected

    def localize_headers(clip_id, keys)
      keys.inject({}) do |memo, key|
        memo[key] = I18n.t("#{clip_id}.schema.#{key}", scope: "dataclips", default: key.to_s)
        memo
      end
    end
  end
end
