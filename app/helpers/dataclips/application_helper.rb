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
        options_for_select: filters_sets.keys.map{|k| [k.to_s.humanize, k]}
      }
    end

    def insight(insight, options = {})
      width          = options.fetch(:width, "100%")
      height         = options.fetch(:height, "500")
      theme          = options.fetch(:theme, "default")
      locale         = options.fetch(:locale, I18n.locale)

      render "dataclips/shared/iframe", {
        id:     dom_id(insight),
        width:  width,
        height: height,
        src:    dataclips.insight_path(insight, locale: locale, theme: theme)
      }
    end
  end
end
