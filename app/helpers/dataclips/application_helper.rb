module Dataclips::ApplicationHelper
  # visual options:  limit
  def find_and_display_insight(clip_id, params = {}, options = {}, &block)
    options.stringify_keys!
    params.stringify_keys!

    # insight options: time_zone, per_page, connection, schema
    insight = Dataclips::Insight.get!(clip_id, params, options.slice('time_zone', 'per_page', 'connection', 'schema'))
    display_insight(insight, options, &block)
  end

  def display_insight(insight, options = {}, &block)
    config     = dataclips_insight_config(insight, options).to_json
    formatters = load_custom_dataclips_formatters(insight) || {}
    options    = load_custom_dataclips_options(insight) || {}

    "<div class='insight' id='#{dom_id(insight)}'></div>
    <script>
      new Dataclips(#{config}, #{formatters}, #{options}).init(function(insight){
        #{capture(&block) if block_given?}
      });
    </script>".html_safe
  end

  private

  def dataclips_insight_config(insight, options = {})
    options.stringify_keys!

    remember_schema_config = options.fetch('remember_schema_config', true)
    disable_seconds = options.fetch('disable_seconds', false)
    selectable = options.fetch('selectable', false)

    schema = load_dataclip_insight_schema(insight)
    if remember_schema_config
      schema_md5 = Digest::MD5.hexdigest(Marshal.dump(schema.to_json))
      identifier = "#{insight.clip_id}-#{schema_md5}"
    end

    {
      url: dataclips.data_insight_path(insight),
      identifier: identifier,
      dom_id: dom_id(insight),
      per_page: insight.per_page,
      schema: schema,
      name: insight.name,
      limit: options['limit'],
      time_zone: insight.time_zone,
      disable_seconds: disable_seconds,
      selectable: selectable
    }.compact
  end

  def load_custom_dataclips_formatters(insight)
    formatters_path = "#{Rails.root}/app/dataclips/#{insight.clip_id}/formatters.js"
    if File.exists?(formatters_path)
      File.read(formatters_path)
    end
  end

  def load_custom_dataclips_options(insight)
    options_path = "#{Rails.root}/app/dataclips/#{insight.clip_id}/options.js"
    if File.exists?(options_path)
      File.read(options_path)
    end
  end

  def load_dataclip_insight_schema(insight)
    file = File.read "#{Rails.root}/app/dataclips/#{insight.clip_id}/schema.json"
    schema = JSON.parse(file)
    locale = I18n.locale

    schema.keys.each do |key|
      translation_path = "dataclips.#{insight.clip_id.gsub('/', '.')}.schema.#{key}"
      schema[key]['label'] = t(translation_path,  default: key)
      dictionary_name = schema[key]['dictionary']
      if dictionary_name.present?
        dictionary = Dataclips::Engine.config.dictionaries[dictionary_name.to_sym]

        if dictionary
          schema[key]['dictionary'] = dictionary.call(insight.params).reduce({}) do |memo, key|
            memo[key] = I18n.t("dataclips.dictionaries.#{dictionary_name}.#{key}", locale: locale, default: key)
            memo
          end
        else
          schema[key].delete('dictionary')
        end
      end
    end
    schema
  end
end
