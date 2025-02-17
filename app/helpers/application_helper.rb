module ApplicationHelper
  module DateOperations
    def self.date_hash_to_time_obj(hash)
      # Extract the timestamp and convert it to seconds
      timestamp_ms = hash.dig("$date", "$numberLong").to_i
      timestamp_seconds = timestamp_ms / 1000

      # Convert to Time object
      datetime = Time.at(timestamp_seconds)
      datetime
    end

    def self.extract_year_from_date_hash(hash)
      year = self.date_hash_to_time_obj(hash).year
      year
    end
  end
end
