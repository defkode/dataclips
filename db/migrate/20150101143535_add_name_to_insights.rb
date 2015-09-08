class AddNameToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :name, :string
  end
end
