module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    config.before_configuration do
      config.path           = Rails.root.join('app/dataclips').to_s
      config.hash_id_length = 6
    end
  end
end
