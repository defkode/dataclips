module Dataclips
  module ApplicationHelper
    def insight_url(insight, locale = I18n.locale)
      dataclips.insight_path(insight, locale: locale)
    end

    def download_insight_url(insight)
      dataclips.export_insight_path(insight, format: :csv)
    end

    def insight(insight, options = {})
      render "dataclips/shared/iframe", id: dom_id(insight), width: options[:width] || "100%", height: options[:height] || "500", src: dataclips.insight_path(insight, embedded: 1, locale: I18n.locale)
    end

    def clip_title(clip)
      context = if title = Dataclips::Engine.config.titles[clip.id.to_sym]
        title.call(clip.context)
      else
        clip.context
      end

      t("#{clip.id}.title", context.merge(default: clip.id.titleize, scope: :dataclips))
    end
  end
end
