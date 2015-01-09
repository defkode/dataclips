module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    config.before_configuration do
      config.dictionaries = {}
      config.salt         = Rails.application.secrets.secret_key_base
      config.path         = Rails.root.join('app/dataclips').to_s
      config.watchable_files.concat Dir.glob("#{config.path}/*.sql")
    end

    # config.before_initialize do
    # end

    initializer "dataclips.assets.precompile" do |app|
      %w(stylesheets javascripts fonts images).each do |sub|
        app.config.assets.paths << root.join('app/assets', sub).to_s
      end
      app.config.assets.precompile << %r(bootstrap/glyphicons-halflings-regular\.(?:eot|svg|ttf|woff2?)$)
    end

    config.to_prepare do |reloader|
      Dataclips.reload!
    end

    # config.after_initialize do
    # end
  end
end
