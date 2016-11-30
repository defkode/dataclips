namespace :dataclips do
  desc "HealthCheck"
  task health_check: :environment do
    Dataclips::Insight.pluck(:clip_id).uniq.sort.each do |clip_id|
      clip_path = File.join(Dataclips::Engine.config.path, "#{clip_id}.sql")
      puts "#{clip_id}.sql ... NOT FOUND" unless File.exists?(clip_path)
    end
  end

  desc "Fix Checksums"
  task fix_checksums: :environment do
    Dataclips::Insight.find_each do |i|
      if i.checksum != Dataclips::Insight.calculate_checksum(i.clip_id, i.params)
        puts i.inspect
        i.checksum = Dataclips::Insight.calculate_checksum(i.clip_id, i.params)
        i.save!
      else
        puts "."
      end
    end
  end

  desc "Delete insights for clip_id"
  task :delete_insights, [:clip_id] => :environment do |t, args|
    Dataclips::Insight.where(clip_id: args.clip_id).delete_all
  end


  desc "Update query for clip_id"
  task :update_insights, [:clip_id] => :environment do |t, args|
    Dataclips::Insight.where(clip_id: args.clip_id).find_each do |i|
      clip = Dataclips::Clip.new(i.clip_id)
      query = clip.query(i.params || {})

      i.update!({
        query: query,
        schema: clip.schema.to_json,
        per_page: clip.per_page
      })
    end
  end
end
