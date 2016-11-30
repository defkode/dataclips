class AddLastViewedAtToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :last_viewed_at, :datetime
    add_column :dataclips_insights, :per_page, :integer # null means don't paginate


    Dataclips::Insight.reset_column_information

    Dataclips::Insight.find_each do |d|
      clip = Dataclips::Clip.new(d.clip_id)

      d.update!({
        per_page: clip.per_page
      })
    end
  end
end
