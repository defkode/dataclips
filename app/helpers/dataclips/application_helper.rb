module Dataclips::ApplicationHelper
  def find_and_display_insight(clip_id, params = {}, options = {}, &block)
    insight = Dataclips::Insight.get!(clip_id, params, options)
    display_insight(insight, &block)
  end

  def display_insight(insight, &block)
    config        = dataclips_insight_config(insight).to_json
    custom_config = load_custom_dataclips_formatters(insight)

    "<div id='#{dom_id(insight)}'></div>
    <script>
      new Dataclips(#{config}, #{custom_config}).init(function(insight){
        #{capture(&block) if block_given?}
      });
    </script>".html_safe
  end

  private

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
    file = File.read "#{Rails.root}/app/dataclips/#{insight.clip_id}.json"
    schema = JSON.parse(file)
    lcoale = I18n.locale

    schema.keys.each do |key|
      schema[key]['label'] = t("dataclips.#{insight.clip_id}.#{key}", default: key)
      dictionary_name = schema[key]['dictionary']
      if dictionary_name.present?
        dictionary = Dataclips::Engine.config.dictionaries[dictionary_name.to_sym].call(insight.params)

        schema[key]['dictionary'] = dictionary.reduce({}) do |memo, key|
          memo[key] = I18n.t("dataclips.dictionaries.#{dictionary_name}.#{key}", locale: locale, default: key)
          memo
        end
      end
    end
    schema
  end
end
