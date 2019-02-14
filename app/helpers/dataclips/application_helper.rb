module Dataclips::ApplicationHelper
  def find_and_display_insight(clip_id, params)
    insight = Dataclips::Insight.get!(clip_id, params)
    display_insight(insight)
  end

  def display_insight(insight)
    config            = dataclips_insight_config(insight).to_json
    custom_formatters = load_custom_dataclips_formatters(insight)

    script_tag = if custom_formatters
      "<script>\nnew Dataclips(#{config}, #{custom_formatters}).init();\n</script>"
    else
      "<script>\nnew Dataclips(#{config}).init();</script>"
    end

    "<div id='#{dom_id(insight)}'></div>\n#{script_tag}".html_safe
  end

  def dataclips_insight_config(insight)
    {
      url:        dataclips.data_insight_path(insight),
      identifier: insight.hash_id,
      dom_id:     dom_id(insight),
      per_page:   insight.per_page,
      schema:     load_dataclip_insight_schema(insight),
      name:       insight.name
    }
  end

  def load_custom_dataclips_formatters(insight)
    formatters_path = "#{Rails.root}/app/dataclips/#{insight.clip_id}.js"
    if File.exists?(formatters_path)
      File.read(formatters_path)
    end
  end

  def load_dataclip_insight_schema(insight)
    file = File.read "#{Rails.root}/app/dataclips/#{@insight.clip_id}.json"
    schema = JSON.parse(file)
    schema.keys.each do |key|
      schema[key]['label'] = t("dataclips.#{insight.clip_id}.#{key}", default: key)
    end
    schema
  end
end
