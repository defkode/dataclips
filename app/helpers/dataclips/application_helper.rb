module Dataclips::ApplicationHelper
  def dataclips_insight_config(insight)
    {
      url:      dataclips.data_insight_path(insight),
      dom_id:   dom_id(insight),
      per_page: insight.per_page,
      schema:   load_dataclip_insight_schema(insight),
      name:     insight.name     
    }
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
