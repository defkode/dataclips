class AddConstraintsToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :checksum, :string

    Dataclips::Insight.find_each { |insight| insight.save! }

    change_column_null :dataclips_insights, :checksum, false
    add_index :dataclips_insights, :checksum, unique: true
  end
end
