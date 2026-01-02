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
      return unless leaderboard_data && leaderboard_data["leaderboardRows"]

      # Get all drafted match picks for this tournament
      drafted_picks = MatchPick.where(tournament: @tournament, drafted: true)
                               .includes(:golfer, :scores)

      # Find WD golfers in leaderboard data
      leaderboard_data["leaderboardRows"].each do |player_data|
        next unless player_data["status"] == "wd"

        # Find the match_pick for this WD golfer
        match_pick = drafted_picks.find { |pick| pick.golfer.source_id == player_data["playerId"] }
        next unless match_pick

        process_wd_replacement(match_pick, player_data, leaderboard_data)
      end
    end

    private

    def process_wd_replacement(match_pick, wd_player_data, leaderboard_data)
      # Prevent duplicate replacement
      return if match_pick.original_golfer_id.present?

      # Get last known position from scores table
      last_position = get_last_known_position(match_pick)

      if last_position.nil?
        # Early WD - no previous API call, use any golfer from leaderboard
        eligible_golfers = find_eligible_replacement_golfers("1", leaderboard_data)
        reason = "wd_early"
      else
        # Normal WD - find golfers at same/worse position
        eligible_golfers = find_eligible_replacement_golfers(last_position, leaderboard_data)
        reason = "wd"
      end

      # Fallback to all undrafted tournament golfers if leaderboard has none
      if eligible_golfers.empty?
        Rails.logger.warn "No eligible golfers in leaderboard, falling back to all undrafted in tournament"
        eligible_golfers = get_all_undrafted_golfers
      end

      if eligible_golfers.empty?
        Rails.logger.error "No eligible replacement golfers for match_pick #{match_pick.id}"
        return
      end

      # Select random replacement and execute
      replacement = select_random_replacement(eligible_golfers)
      execute_replacement(match_pick, replacement, @current_round, reason) if replacement
    rescue StandardError => e
      Rails.logger.error "WD replacement failed for match_pick #{match_pick.id}: #{e.message}"
    end

    def get_last_known_position(match_pick)
      match_pick.scores.where.not(position: nil).order(round: :desc).first&.position
    end

    def find_eligible_replacement_golfers(position, leaderboard_data)
      target_position = parse_position_for_comparison(position)
      already_drafted = MatchPick.where(tournament: @tournament, drafted: true).pluck(:golfer_id)

      eligible = []
      leaderboard_data["leaderboardRows"].each do |player|
        player_position = parse_position_for_comparison(player["position"])
        golfer = Golfer.find_by(source_id: player["playerId"])

        # Include if: at same/worse position AND not already drafted AND not WD
        if golfer && player_position >= target_position && !already_drafted.include?(golfer.id) && player["status"] != "wd"
          eligible << golfer
        end
      end

      eligible
    end

    def select_random_replacement(eligible_golfers)
      return nil if eligible_golfers.empty?

      eligible_golfers.sample
    end

    def execute_replacement(match_pick, replacement_golfer, round, reason)
      match_pick.update!(
        original_golfer_id: match_pick.golfer_id,
        golfer_id: replacement_golfer.id,
        replaced_at_round: round,
        replacement_reason: reason
      )

      Rails.logger.info "WD Replacement: match_pick=#{match_pick.id}, original=#{match_pick.original_golfer_id}, new=#{replacement_golfer.id}, round=#{round}, reason=#{reason}"
    end

    def parse_position_for_comparison(position)
      return Float::INFINITY if position.nil? || %w[CUT WD].include?(position)

      # Remove "T" prefix for tied positions: "T5" → 5, "1" → 1
      position.to_s.gsub(/[^0-9]/, "").to_i
    end

    def get_all_undrafted_golfers
      already_drafted = MatchPick.where(tournament: @tournament, drafted: true).pluck(:golfer_id)
      Golfer.where(last_active_tourney: @tournament.unique_id)
            .where.not(id: already_drafted)
    end
  end
end
