module BusinessLogic
  # MatchResultsCalculationService calculates final tournament results for all users
  # Assigns placements (1st-4th) and calculates points based on total strokes
  class MatchResultsCalculationService
    def initialize(tournament)
      @tournament = tournament
    end

    def calculate
      # Get all users with drafted picks for this tournament
      users_with_picks = User.joins(:match_picks)
                             .where(match_picks: { tournament: @tournament, drafted: true })
                             .distinct

      # Calculate total strokes for each user
      user_totals = users_with_picks.map do |user|
        total_strokes = calculate_user_total_strokes(user)
        { user: user, total_strokes: total_strokes }
      end

      # Sort by total strokes (lowest first)
      user_totals.sort_by! { |ut| ut[:total_strokes] }

      # Assign placements and create match results
      user_totals.each_with_index do |user_total, index|
        place = index + 1
        points = calculate_points(place)

        MatchResult.create!(
          tournament: @tournament,
          user: user_total[:user],
          place: place,
          total_score: points,
          winner_picked: false,
          cuts_missed: 0
        )
      end

      Rails.logger.info "Match results calculated for tournament #{@tournament.id}"
    end

    private

    def calculate_user_total_strokes(user)
      # Get all drafted picks for this user in this tournament
      match_picks = MatchPick.where(user: user, tournament: @tournament, drafted: true)

      total = 0
      match_picks.each do |match_pick|
        # Sum all scores for this match_pick (4 rounds per golfer)
        golfer_total = Score.where(match_pick: match_pick).sum(:score)
        total += golfer_total
      end

      total
    end

    def calculate_points(place)
      case place
      when 1
        -4
      when 2
        -3
      when 3
        -2
      when 4
        -1
      else
        0
      end
    end
  end
end
