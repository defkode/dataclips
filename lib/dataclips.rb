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
  def hashids
    @hashids ||= Hashids.new(Dataclips::Engine.config.salt, 8)
  end

  module_function :hashids
end
