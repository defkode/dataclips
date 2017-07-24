module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    config.before_configuration do
      config.dictionaries = {}
      config.path         = Rails.root.join('app/dataclips').to_s
      config.themes       = {
        "default" => {
          "css" => ["//fonts.googleapis.com/css?family=Inconsolata:400,700&subset=latin,latin-ext", "//maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css", "dataclips/application.css", "dataclips/dataclips.css"],
          "progressbar_color" => "#6F5498"
        }
      }
    end
  end
end
