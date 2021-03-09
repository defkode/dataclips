namespace :dataclips do
  desc "HealthCheck"
  task health_check: :environment do
    Dataclips::Insight.pluck(:clip_id).uniq.sort.each do |clip_id|
      puts "#{clip_id}/query.sql ... NOT FOUND" unless Dataclips.available.include?(clip_id)
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
