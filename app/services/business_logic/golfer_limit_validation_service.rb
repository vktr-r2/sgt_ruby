module BusinessLogic
  class GolferLimitValidationService
    def initialize(user_id, current_picks)
      @user_id = user_id
      @current_picks = current_picks # Array of golfer IDs being submitted
      @current_year = Date.current.year
    end

    def validate
      violations = []

      # Get all tournament unique_ids for current year
      current_year_tournaments = get_current_year_tournaments
      return { valid: true, violations: [] } if current_year_tournaments.empty?

      # Get all golfer IDs already picked by user in current year where drafted = true
      existing_picks = get_existing_picks(current_year_tournaments)

      # Check each current pick against the limit
      @current_picks.each do |golfer_id|
        existing_count = existing_picks.count(golfer_id)
        if existing_count >= MatchPick::GOLFER_SELECTION_LIMIT
          golfer_name = get_golfer_name(golfer_id)
          violations << {
            golfer_id: golfer_id,
            golfer_name: golfer_name,
            current_count: existing_count,
            message: "Scottie Scheffler rule violation: You have already selected #{golfer_name} #{MatchPick::GOLFER_SELECTION_LIMIT} times this year, please choose another golfer"
          }
        end
      end

      {
        valid: violations.empty?,
        violations: violations
      }
    end

    private

    def get_current_year_tournaments
      year_start = Date.new(@current_year, 1, 1)
      year_end = Date.new(@current_year, 12, 31)

      Tournament.where("start_date >= ? AND start_date <= ?", year_start, year_end)
                .pluck(:unique_id)
    end

    def get_existing_picks(tournament_unique_ids)
      MatchPick.joins(:tournament)
              .where(user_id: @user_id)
              .where(tournaments: { unique_id: tournament_unique_ids })
              .pluck(:golfer_id)
    end

    def get_golfer_name(golfer_id)
      golfer = Golfer.find_by(id: golfer_id)
      return "Unknown Golfer" unless golfer

      "#{golfer.f_name} #{golfer.l_name}".strip
    end
  end
end
