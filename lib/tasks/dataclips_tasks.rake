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

  desc "Delete insights for clip_id"
  task :delete_insights, [:clip_id] => :environment do |t, args|
    Dataclips::Insight.where(clip_id: args.clip_id).delete_all
  end

  desc "Migrate dataclips schema yml"
  task migrate_schema: :environment do
    Dir.glob('app/dataclips/**/*.yml').each do |path|
      File.open(path.gsub('.yml', '.json'), 'w') do |file|
        file.write(
          JSON.pretty_generate(
            YAML.load(
              File.read(path)
            )["schema"]
          )
        )
      end
    end
  end
end
