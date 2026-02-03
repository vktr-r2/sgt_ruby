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

      # Find tournament winner (golfer with lowest total score across ALL users)
      tournament_winner_golfer_id = find_tournament_winner

      # Calculate total strokes for each user
      user_totals = users_with_picks.map do |user|
        total_strokes = calculate_user_total_strokes(user)
        cuts_missed = count_cuts_missed(user)
        drafted_winner = user_drafted_golfer?(user, tournament_winner_golfer_id)

        { user: user, total_strokes: total_strokes, cuts_missed: cuts_missed, drafted_winner: drafted_winner }
      end

      # Sort by total strokes (lowest first)
      user_totals.sort_by! { |ut| ut[:total_strokes] }

      # Assign placements and create match results
      user_totals.each_with_index do |user_total, index|
        place = index + 1
        points = calculate_points(place)

        # Add major championship bonus for winner
        if @tournament.major_championship && place == 1
          points -= 2
        end

        # Add winner picked bonus
        if user_total[:drafted_winner]
          points -= 1
        end

        MatchResult.create!(
          tournament: @tournament,
          user: user_total[:user],
          place: place,
          total_score: points,
          winner_picked: user_total[:drafted_winner],
          cuts_missed: user_total[:cuts_missed]
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

    def find_tournament_winner
      # Find actual tournament winner from leaderboard snapshot (position = "1")
      snapshot = LeaderboardSnapshot.find_by(tournament: @tournament)
      return nil unless snapshot&.leaderboard_data

      # Find player with position "1" (tournament winner)
      winner_data = snapshot.leaderboard_data.find { |p| p["position"] == "1" }
      return nil unless winner_data

      winner_source_id = winner_data["player_id"]
      return nil unless winner_source_id

      # Find golfer in our database by source_id
      winner_golfer = Golfer.find_by(source_id: winner_source_id)
      winner_golfer&.id
    end

    def user_drafted_golfer?(user, golfer_id)
      return false if golfer_id.nil?

      MatchPick.exists?(user: user, tournament: @tournament, golfer_id: golfer_id, drafted: true)
    end

    def count_cuts_missed(user)
      # Get all drafted picks for this user
      match_picks = MatchPick.where(user: user, tournament: @tournament, drafted: true)

      cuts_count = 0
      match_picks.each do |match_pick|
        # Check if any score has status "cut"
        has_cut = Score.exists?(match_pick: match_pick, status: "cut")
        cuts_count += 1 if has_cut
      end

      cuts_count
    end
  end
end
