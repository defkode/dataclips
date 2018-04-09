require "dataclips/engine"

module Dataclips
<<<<<<< HEAD
=======
  def reload!
    Dir.chdir(Dataclips::Engine.config.path) do
      Dir.glob("**/*.sql") do |path|

        clip_id = path.gsub("/", "_").sub(".sql", "_clip") # orders.sql => orders
        Rails.logger.debug "reloading: #{clip_id}"

        clip_class_name = clip_id.camelize

        remove_const(clip_class_name) if const_defined?(clip_class_name)

        sql = SQLQuery.new File.read(path)

        klass = Class.new(Clip) do
          @template   = sql.template
          @schema     = sql.schema
          @per_page   = sql.options["per_page"]
          @connection = sql.options["connection"]
          @variables  = sql.variables

          attr_accessor *sql.variables.keys

          sql.variables.each do |key, options|
            validates key, date: options[:type] == "date"
          end
        end

        const_set(clip_class_name, klass)
      end
    end
  end

  def hashids
    @hashids ||= Hashids.new(Dataclips::Engine.config.salt, 8)
  end

  module_function :hashids, :reload!
>>>>>>> 2a74ae69e1f234159a64ed3195efc7617ce2e820
end
