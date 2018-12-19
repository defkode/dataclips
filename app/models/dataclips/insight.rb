module Dataclips
  class Insight < ActiveRecord::Base
    class FileNotFound < ArgumentError; end

    validates :clip_id, presence: true
    validates :hash_id, presence: true, uniqueness: true
    validates :checksum, presence: true, uniqueness: true
    validates :time_zone, presence: true

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

    def self.get!(clip_id, params = {}, options = {})
      schema    = options[:schema]
      time_zone = options[:time_zone] || Rails.configuration.time_zone

      name      = options.fetch(:name, clip_id)
      checksum = calculate_checksum(clip_id, params, schema)

      if insight = Dataclips::Insight.find_by(clip_id: clip_id, checksum: checksum)
        return insight
      else
        hash_id = SecureRandom.urlsafe_base64(6)

        if basic_auth = options[:basic_auth]
          if basic_auth[:username].present? && basic_auth[:password].present?
            basic_auth_credentials = [basic_auth[:username], basic_auth[:password]].join(":")
          end
        end

        Dataclips::Insight.create!({
          clip_id:   clip_id,
          hash_id:   hash_id,
          name:      name,
          params:    params,
          schema:    schema,
          basic_auth_credentials: basic_auth_credentials,
          time_zone: time_zone
        })
      end
    end

    def self.calculate_checksum(clip_id, params, schema)
      Digest::MD5.hexdigest Marshal.dump({clip_id: clip_id, params: params, schema: schema}.to_json)
    end

    def set_checksum
      self.checksum = self.class.calculate_checksum(clip_id, params, schema)
    end
  end
end
