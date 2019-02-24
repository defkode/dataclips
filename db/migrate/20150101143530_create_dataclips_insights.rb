class CreateDataclipsInsights < ActiveRecord::Migration[5.2]
  def change
    execute "DROP TABLE IF EXISTS dataclips_insights;"
    create_table :dataclips_insights do |t|
      t.string  :hash_id, null: false

      t.string  :clip_id, null: false
      t.json    :params

      t.string  :checksum, null: false
      t.string  :time_zone, null: false
      t.string  :name
      t.string  :connection
      t.integer :per_page
      t.string  :schema
      t.string  :basic_auth_credentials
      t.datetime :last_viewed_at
      t.timestamps
    end

    add_index :dataclips_insights, :clip_id
    add_index :dataclips_insights, :checksum, unique: true
    add_index :dataclips_insights, :hash_id, unique: true
    add_index :dataclips_insights, :schema
  end
end
