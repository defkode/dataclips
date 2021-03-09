module Dataclips
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_initializer
      initializer "dataclips.rb" do
        <<-ruby
          require 'dataclips/engine'

          # Dataclips::Engine.config.hash_id_length = 6
          # Dataclips::Engine.config.path = Rails.root.join('app/dataclips').to_s
          # Dataclips::Engine.config.dictionaries = {
          #   time_zones: -> (insight_params) { ActiveSupport::TimeZone.all.map(&:name) },
          # }
        ruby
      end
    end

    def setup_dataclips_folder
      empty_directory Rails.root.join('app/dataclips').to_s
    end

    def mount_engine
      route "mount Dataclips::Engine, at: '/dataclips', as: :dataclips"
    end

    def install_and_run_migrations
      rails_command "dataclips:install:migrations"
      rails_command "db:migrate"
    end
  end
end
