class AddExcludesToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :excludes, :string, array: true, default: '{}'
  end
end
