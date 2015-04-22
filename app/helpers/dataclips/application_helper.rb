module Dataclips
  module ApplicationHelper
    def insight(insight)
      render "dataclips/shared/iframe", id: dom_id(insight), src: dataclips.insight_path(insight, embedded: 1)
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
