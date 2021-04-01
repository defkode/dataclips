namespace :dataclips do
  desc "HealthCheck"
  task health_check: :environment do
    Dataclips::Insight.distinct.pluck(:clip_id).each do |clip_id|
      if Dataclips::QueryTemplate.all.exclude?(clip_id)
        puts "#{clip_id}/query.sql ... NOT FOUND"
      else
        puts "#{clip_id}/query.sql ... OK"
      end
    end
  end

  desc "Fix Checksums"
  task fix_checksums: :environment do
    Dataclips::Insight.find_each do |i|
      if i.checksum != Dataclips::Insight.calculate_checksum(i.clip_id, i.params, i.per_page, i.connection)
        puts "#{i.hash_id}: #{i.clip_id}, #{i.params}"
        i.checksum = Dataclips::Insight.calculate_checksum(i.clip_id, i.params, i.per_page, i.connection)
        i.save!
      else
        puts "."
      end
    end
  end
end
