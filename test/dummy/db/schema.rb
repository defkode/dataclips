# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150101143530) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dataclips_insights", id: :serial, force: :cascade do |t|
    t.string "clip_id", null: false
    t.string "schema"
    t.string "hash_id", null: false
    t.string "checksum", null: false
    t.string "time_zone"
    t.string "name"
    t.string "basic_auth_credentials"
    t.json "params"
    t.datetime "last_viewed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["checksum"], name: "index_dataclips_insights_on_checksum", unique: true
    t.index ["clip_id"], name: "index_dataclips_insights_on_clip_id"
    t.index ["hash_id"], name: "index_dataclips_insights_on_hash_id", unique: true
    t.index ["schema"], name: "index_dataclips_insights_on_schema"
  end

end
