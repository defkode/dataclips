namespace :dataclips do
  desc "HealthCheck"
  task health_check: :environment do
    Dataclips::Insight.pluck(:clip_id).uniq.sort.each do |clip_id|
      clip_path = File.join(Dataclips::Engine.config.path, "#{clip_id}.sql")
      puts "#{clip_id}.sql ... NOT FOUND" unless File.exists?(clip_path)
    end
  end

  desc "Delete insights for clip_id"
  task :delete_insights, [:clip_id] => :environment do |t, args|
    Dataclips::Insight.where(clip_id: args.clip_id).delete_all
  end
end
