module BusinessLogic
  class TournamentService
    MAJORS = [
      "masters tournament",
      "pga championship",
      "the open championship",
      "u.s. open"
    ].freeze

    def initialize(date = Date.today)
      @date = date
    end

    def current_tournament
      tourn_results = fetch_current_tournaments
      
      # If no tournaments found for current week, check for tournaments in draft window
      if tourn_results.empty?
        tourn_results = fetch_tournaments_in_draft_window
      end
      
      return tourn_results.first unless more_than_one_current_tourn?(tourn_results)

      determine_more_valuable_tourn(tourn_results)
    end

    def current_tournament_id
      current_tournament[:tournament_id]
    end

    def current_tournament_unique_id
      current_tournament[:unique_id]
    end

    def is_major?(name)
      return false if name.nil? || name.empty?
      MAJORS.include?(name.downcase)
    end

    private
    def fetch_current_tournaments
      Tournament.where(
        week_number: current_week,
        year: @date.year
      )
    end

    def fetch_tournaments_in_draft_window
      # Find tournaments where current date is within their draft window
      # Draft window is 2 days before tournament starts to 1 day before tournament starts
      current_time = Time.zone.now
      
      Tournament.where(year: @date.year).select do |tournament|
        tournament.draft_window_open?(current_time)
      end
    end

    def current_week
      @date.strftime("%V").to_i
    end

    def more_than_one_current_tourn?(tourn_results)
      tourn_results.length > 1
    end

    def determine_more_valuable_tourn(tourn_results)
      tourn_results.max_by { |t| t.purse || 0 }
    end
  end
end
