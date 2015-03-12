module Dataclips
  class Engine < ::Rails::Engine
    isolate_namespace Dataclips

    # config.watchable_files.concat Dir.glob("#{Dataclips.path}/*.sql")
    # Add a prepare callback. Prepare callbacks are run before each request, prior to ActionDispatch::Callback’s before callbacks.
    # config.to_prepare do
    #   Dir.glob("#{Dataclips.path}/*.sql") do |clip_path|
    #     clip_id = clip_path.match(/(\w+).sql/)[1]
    #     sql = Dataclips.read_sql(clip_id)

    #     klass = Class.new(Clip) do
    #       @template  = sql.template
    #       @schema    = sql.schema
    #       @per_page  = sql.options["per_page"]
    #       @variables = sql.variables

    #       attr_accessor *sql.variables.keys

    #       sql.variables.each do |key, options|
    #         validates key, date: options[:type] == "date"
    #       end
    #     end

    #     ::Dataclips::Clip.const_set(clip_id.camelize, klass)
    #   end
    # end


    config.before_configuration do
      puts "DATACLIPS:BEFORE_CONFIGURATION"
      config.dictionaries = {}
      config.salt         = Rails.application.secrets.secret_key_base
      config.path         = Rails.root.join('app/dataclips').to_s
      config.watchable_files.concat Dir.glob("#{config.path}/*.sql")
    end

    config.before_initialize do
      puts "DATACLIPS:BEFORE_INITIALIZE"
    end

    initializer "dataclips.assets.precompile" do |app|
      %w(stylesheets javascripts fonts images).each do |sub|
        app.config.assets.paths << root.join('app/assets', sub).to_s
      end
      app.config.assets.precompile << %r(bootstrap/glyphicons-halflings-regular\.(?:eot|svg|ttf|woff2?)$)
    end

    config.to_prepare do |reloader|
      puts reloader.inspect
      puts "DATACLIPS::TO_PREPARE"
    end

    config.after_initialize do
      puts config.dictionaries.inspect
      puts Rails.application.watchable_args.inspect
      puts "DATACLIPS:AFTER_INITIALIZE"
    end
  end
end
