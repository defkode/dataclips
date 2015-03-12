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
  def read_sql(clip_id)
    SQLQuery.new File.read(File.join(path, "#{clip_id}.sql"))
  end

  def hashids
    Hashids.new(salt, 8)
  end

  module_function :read_sql, :hashids
end
