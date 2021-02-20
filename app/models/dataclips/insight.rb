module Dataclips
  class Insight < ActiveRecord::Base
    class FileNotFound < ArgumentError; end

    validates :clip_id,   presence: true
    validates :hash_id,   presence: true, uniqueness: true
    validates :checksum,  presence: true, uniqueness: true
    validates :time_zone, presence: true
    validates :per_page,  numericality: {greater_than: 0, less_than_or_equal_to: 50_000}, allow_nil: true

    before_validation :set_checksum

    scope :shared, -> { where(shared: true) }

    def to_param
      hash_id
    end

    def name
      read_attribute(:name) || clip_id
    end

    def self.get!(clip_id, params = {}, options = {})
      options.stringify_keys!
      params.stringify_keys!
      time_zone  = options['time_zone'] || Rails.configuration.time_zone
      per_page   = options['per_page']
      connection = options['connection']

      name      = options.fetch('name', clip_id)
      checksum = calculate_checksum(clip_id, params, per_page, connection)

      if insight = Dataclips::Insight.find_by(clip_id: clip_id, checksum: checksum)
        return insight
      else
        hash_id = SecureRandom.urlsafe_base64(Dataclips::Engine.config.hash_id_length)

        Dataclips::Insight.create!({
          clip_id:                clip_id,
          hash_id:                hash_id,
          name:                   name,
          params:                 params,
          time_zone:              time_zone,
          per_page:               per_page,
          connection:             connection
        })
      end
    end

    def self.calculate_checksum(clip_id, params, per_page, connection)
      Digest::MD5.hexdigest Marshal.dump({clip_id: clip_id, params: params, per_page: per_page, connection: connection}.to_json)
    end

    def set_checksum
      self.checksum = self.class.calculate_checksum(clip_id, params, per_page, connection)
    end
  end
end
