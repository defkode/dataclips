require "dataclips/engine"
require "hashids"

class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value.present?
    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors[attribute] << :invalid
    end
  end
end

module Dataclips
  def reload!
    Dir.chdir(Dataclips::Engine.config.path) do
      Dir.glob("**/*.sql") do |path|
        # staff/payment/orders.sql
        namespaces = path.split("/")

        clip_id = namespaces.pop.sub(".sql", "") # orders.sql => orders
        Rails.logger.debug "reloading: #{clip_id}"

        # scope: Staff::Payment
        make_namespaces namespaces do
          clip_class_name = clip_id.camelize

          remove_const(clip_class_name) if const_defined?(clip_class_name)

          sql = SQLQuery.new File.read(path)

          klass = Class.new(Clip) do
            @template  = sql.template
            @schema    = sql.schema
            @per_page  = sql.options["per_page"]
            @variables = sql.variables

            attr_accessor *sql.variables.keys

            sql.variables.each do |key, options|
              validates key, date: options[:type] == "date"
            end
          end

          const_set(clip_class_name, klass)
        end
      end
    end
  end

  def hashids
    @hashids ||= Hashids.new(Dataclips::Engine.config.salt, 8)
  end

  def make_namespaces(namespaces, &block)
    modules = namespaces.each_with_object([self]) do |namespace, modules|
      obj = modules.last
      str = namespace.camelize
      modules << (obj.const_defined?(str) ? obj.const_get(str) : obj.const_set(str, Module.new))
    end
    modules.last.module_exec(&block)
  end

  module_function :hashids, :reload!, :make_namespaces
end
