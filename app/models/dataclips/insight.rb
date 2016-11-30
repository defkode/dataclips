module Dataclips
  class Insight < ActiveRecord::Base
    class FileNotFound < ArgumentError; end

    validates :clip_id, presence: true
    validates :query, presence: true
    validates :schema, presence: true
    validates :hash_id, presence: true, uniqueness: true
    validates :checksum, presence: true, uniqueness: true

    before_validation :set_checksum

    def to_param
      hash_id
    end

    def name
      read_attribute(:name) || clip_id
    end

    def authenticate(login, password)
      basic_auth_credentials == [login,password].join(":")
    end

    def self.get!(clip_id, params = nil)
      clip_path = File.join(Dataclips::Engine.config.path, "#{clip_id}.sql")
      if File.exists?(clip_path)
        checksum = calculate_checksum(clip_id, params)
        if insight = Dataclips::Insight.find_by(clip_id: clip_id, checksum: checksum)
          return insight
        else
          hash_id = Dataclips.hashids.encode(Time.now.to_i + (1..10000).to_a.shuffle.first)
          clip = Dataclips::Clip.new(clip_id)
          query = clip.query(params || {})

          return Dataclips::Insight.create!({
            clip_id: clip_id,
            hash_id: hash_id,
            query: query,
            schema: clip.schema.to_json,
            params: params,
            per_page: clip.per_page,
            name: "#{params.to_s.parameterize}"
          })
        end
      else
        raise FileNotFound.new(clip_path)
      end
    end

    def time_zone
      read_attribute(:time_zone) || Rails.configuration.time_zone
    end

    def self.calculate_checksum(clip_id, params)
      Digest::MD5.hexdigest Marshal.dump({clip_id: clip_id, params: params}.to_json)
    end

    def set_checksum
      self.checksum = self.class.calculate_checksum(clip_id, params)
    end
  end
end
