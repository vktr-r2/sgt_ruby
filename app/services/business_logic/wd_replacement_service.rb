module BusinessLogic
  # WdReplacementService handles automatic replacement of withdrawn (WD) golfers
  # When a golfer withdraws, replaces them with a random golfer at same/worse position
  class WdReplacementService
    def initialize(tournament, current_round)
      @tournament = tournament
      @current_round = current_round
    end

    # Main entry point - detects and replaces all WD golfers in leaderboard data
    def detect_and_replace_wd_golfers(leaderboard_data)
      # TODO: Implementation
    end

    private

    def find_wd_golfers(leaderboard_data)
      # TODO: Filter leaderboard rows where status == "wd"
    end

    def process_wd_replacement(match_pick, wd_player_data)
      # TODO: Core replacement logic
    end

    def get_last_known_position(match_pick)
      # TODO: Query scores table for most recent position
    end

    def find_eligible_replacement_golfers(position, leaderboard_data)
      # TODO: Get golfers at same/worse position, exclude already drafted
    end

    def select_random_replacement(eligible_golfers)
      # TODO: Use .sample to select random golfer
    end

    def execute_replacement(match_pick, replacement_golfer, round, reason)
      # TODO: Update match_pick with new golfer
    end

    def parse_position_for_comparison(position)
      # TODO: Handle "T5", "1", "CUT", "WD" formats
    end

    def get_all_undrafted_golfers
      # TODO: Get all tournament golfers not currently drafted
    end
  end
end
