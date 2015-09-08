module Dataclips
  module ApplicationHelper
    def insight_url(insight, locale = I18n.locale)
      dataclips.insight_path(insight, locale: locale)
    end

    def download_insight_url(insight, locale = I18n.locale)
      dataclips.export_insight_path(insight, locale: locale, format: :csv)
    end

    def insight(insight, options = {})
      render "dataclips/shared/iframe", {
        id:      dom_id(insight),
        width:   options[:width] || "100%",
        height:  options[:height] || "500",
        filters: options[:filters] || {},
        src:     dataclips.insight_path(insight, locale: I18n.locale, theme: options[:theme] || "default")
      }
    end
  end
end
