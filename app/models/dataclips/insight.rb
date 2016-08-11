module Dataclips
  class Insight < ActiveRecord::Base
    class FileNotFound < ArgumentError; end

    validates :clip_id, presence: true
    validates :checksum, presence: true, uniqueness: true

    before_validation :set_checksum

    def to_param
      hash_id
    end

    def name
      read_attribute(:name) || clip_id
    end

    def self.get(clip_id, params = nil)
      find_by(clip_id: clip_id)
    end

    def authenticate(login, password)
      basic_auth_credentials == [login,password].join(":")
    end

    def self.get!(clip_id, params = nil, excludes = [])
      clip_path = File.join(Dataclips::Engine.config.path, "#{clip_id}.sql")
      if File.exists?(clip_path)
        checksum = calculate_checksum(clip_id, params)
        Dataclips::Insight.find_by(clip_id: clip_id, checksum: checksum) || Dataclips::Insight.create!(clip_id: clip_id, name: "#{params.to_s.parameterize}", params: params, excludes: excludes || [])
      else
        raise FileNotFound.new(clip_path)
      end
    end

    def self.find_by_hash_id(hash_id)
      find_by(id: Dataclips.hashids.decode(hash_id))
    end

    def hash_id
      return unless persisted?
      Dataclips.hashids.encode(id)
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
