module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    config.before_configuration do
      config.dictionaries = {}
      config.path         = Rails.root.join('app/dataclips').to_s
      config.include_css  = ""
    end
  end
end
