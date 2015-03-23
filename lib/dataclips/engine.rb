module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    config.before_configuration do
      config.dictionaries = {}
      config.salt         = Rails.application.secrets.secret_key_base
      config.path         = Rails.root.join('app/dataclips').to_s
      config.watchable_files.concat Dir.glob("#{config.path}/*.sql")
    end

    config.to_prepare do |reloader|
      Dataclips.reload!
    end
  end
end
