class CreateDataclipsInsights < ActiveRecord::Migration[5.2]
  def change
    create_table :dataclips_insights do |t|
      t.string  :clip_id, null: false
      t.string  :schema
      t.string  :hash_id, null: false
      t.string  :checksum, null: false
      t.string  :time_zone, null: false
      t.string  :name
      t.string  :basic_auth_credentials

      t.json    :params
      t.datetime :last_viewed_at
      t.timestamps
    end

    add_index :dataclips_insights, :clip_id
    add_index :dataclips_insights, :checksum, unique: true
    add_index :dataclips_insights, :hash_id, unique: true
    add_index :dataclips_insights, :schema
  end
end
