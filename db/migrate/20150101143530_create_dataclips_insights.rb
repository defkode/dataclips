class CreateDataclipsInsights < ActiveRecord::Migration[6.1]
  def change
    create_table "dataclips_insights" do |t|
      t.string "hash_id", null: false
      t.string "clip_id", null: false
      t.json "params"
      t.string "checksum", null: false
      t.string "time_zone", null: false
      t.string "name"
      t.string "connection"
      t.integer "per_page"
      t.datetime "last_viewed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["checksum"], name: "index_dataclips_insights_on_checksum", unique: true
      t.index ["clip_id"], name: "index_dataclips_insights_on_clip_id"
      t.index ["hash_id"], name: "index_dataclips_insights_on_hash_id", unique: true
    end
  end
end
