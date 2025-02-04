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

  module TournamentEvaluations
    def self.is_major?(name)
      name = name.downcase
      majors = [ "masters tournament", "pga championship", "the open championship", "u.s. open" ]
      majors.include?(name)
    end

    def self.determine_current_tournament
      tourn_results = Tournament.where(week_number: determine_current_week, year: Date.today.year)

      if more_than_one_current_tourn?(tourn_results)
        determine_more_valuable_tourn(tourn_results)
      else
        tourn_results.first
      end
    end

    def self.determine_current_tourn_id
      determine_current_tournament[:tournament_id]
    end

    def self.determine_current_tourn_unique_id
      determine_current_tournament[:unique_id]
    end

    def self.more_than_one_current_tourn?(tourn_results)
      tourn_results.length > 1
    end

    def self.determine_more_valuable_tourn(tourn_results)
      greater_purse_tournament = tourn_results.max_by(&:purse)
      greater_purse_tournament
    end

    def self.determine_current_week(date = Date.today)
      date.strftime("%V").to_i
    end
  end
end
