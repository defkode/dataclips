module Dataclips::ApplicationHelper
  # insight stores clip_id, query params, and fetch options (per_page, connection)
  def display_insight(insight, options = {})
    options.stringify_keys!

    clip_id = insight.clip_id

    schema_file     = read_insight_config_file("schema.json", clip_id)
    formatters_file = read_insight_config_file("formatters.js", clip_id)
    filters_file    = read_insight_config_file("filters.json", clip_id)

    display_options = {
      name: insight.name,
      time_zone: insight.time_zone,
      disable_seconds: options.fetch('disable_seconds', false),
      default_filter: options['default_filter'].presence
    }.compact

    # allow caching user config (like column visibility, regardless of changing params like date, user_id etc)
    if options.fetch('cache_user_config', true)
      display_options[:cache_id] = [insight.clip_id, Digest::MD5.hexdigest(schema_file)].join("-") # invalidate cache when schema is changed
    end

    schema = JSON.parse(schema_file)

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

    filters = JSON.parse(filters_file)

    tag.div(class: 'insight', id: dom_id(insight)) +
    javascript_tag do
      "
        const insight = Dataclips.insight('#{dom_id(insight)}',
          #{schema.to_json},
          '#{dataclips.data_insight_path(insight)}',
          #{formatters_file},
          #{display_options.to_json},
          #{filters.to_json}
        );
        insight.fetch();
      ".html_safe
    end
  end

  private

  def read_insight_config_file(filename, clip_id)
    config_file_path = File.join(Dataclips::Engine.config.path, clip_id, filename)
    File.read(config_file_path) if File.exists?(config_file_path)
  end
end
