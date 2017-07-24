module Dataclips
  module ApplicationHelper
    def insight_url(insight, locale = I18n.locale)
      dataclips.insight_path(insight, locale: locale)
    end

    def download_insight_url(insight, locale = I18n.locale)
      dataclips.export_insight_path(insight, locale: locale, format: :csv)
    end

    def insight_filters(insight, filters_sets = {}, default_filter = "default")
      filters_sets = {all: {}}.merge(filters_sets)
      render "dataclips/shared/filters", {
        id:             dom_id(insight),
        filters_sets:   filters_sets,
        default_filter: default_filter,
        options_for_select: filters_sets.keys.map do |k|
          [
            I18n.t(k, scope: "dataclips.#{insight.clip_id}.filters", default: k.to_s),
            k
          ]
        end
      }
    end

    def insight(insight, options = {})
      id             = options.fetch(:id, dom_id(insight))
      locale         = options.fetch(:locale, I18n.locale)
      sidebar        = options.fetch(:sidebar, true)

      render "dataclips/shared/iframe", {
        id:      id,
        src:     dataclips.insight_path(insight, {locale: locale, sidebar: sidebar ? 1 : 0})
      }
    end
  end
end
