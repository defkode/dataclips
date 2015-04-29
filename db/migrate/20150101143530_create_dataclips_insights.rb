class CreateDataclipsInsights < ActiveRecord::Migration
  def change
    create_table :dataclips_insights do |t|
      t.string  :clip_id, null: false
      t.json    :params
      t.timestamps
    end

    add_index :dataclips_insights, :clip_id
  end
end
