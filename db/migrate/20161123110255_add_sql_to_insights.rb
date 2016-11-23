class AddSqlToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :query, :text
    add_column :dataclips_insights, :hash_id, :string

    add_index :dataclips_insights, :hash_id, unique: true

    Dataclips::Insight.reset_column_information

    hashids = Hashids.new(Rails.application.secrets.secret_key_base, 8)

    Dataclips::Insight.find_each do |d|
      clip = Dataclips::Clip.new(d.clip_id)
      d.update!({
        query: clip.query(d.params || {}).squish,
        hash_id: hashids.encode(d.id)
      })
    end


    change_column_null :dataclips_insights, :hash_id, false
    change_column_null :dataclips_insights, :query, false
  end
end
