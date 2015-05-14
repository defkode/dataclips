class AddTimeZoneToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :time_zone, :string
  end
end
