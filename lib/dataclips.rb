require "dataclips/engine"

module Dataclips
  def available
    Dir.glob('app/dataclips/**/*/query.sql').map do |query_path|
      query_path.gsub('app/dataclips/', '').gsub('/query.sql', '')
    end
  end

  module_function :available
end
