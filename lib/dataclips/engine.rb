module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    initializer "dataclips.assets.precompile" do |app|
      %w(stylesheets javascripts fonts images).each do |sub|
        app.config.assets.paths << root.join('app/assets', sub).to_s
      end
      app.config.assets.precompile << %r(bootstrap/glyphicons-halflings-regular\.(?:eot|svg|ttf|woff2?)$)
    end
  end
end
