class CreateDataclipsInsights < ActiveRecord::Migration
  def change
    create_table :dataclips_insights do |t|
      t.string  :clip_id, null: false
      t.string  :owner_gid
      t.json    :schema, default: {}
      t.json    :params, default: {}
      t.timestamps
    end

    add_index :dataclips_insights, :clip_id
    add_index :dataclips_insights, [:clip_id, :owner_gid], unique: true
  end
end
