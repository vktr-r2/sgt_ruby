module BusinessLogic
  class SnakeDraftService
    def initialize
      @tournament_service = BusinessLogic::TournamentService.new
    end

    def execute_draft(tournament = nil)
      @tournament = tournament || @tournament_service.current_tournament
      return { success: false, error: "No tournament found" } unless @tournament

      users = User.all.to_a
      return { success: false, error: "No users found" } unless users.any?

      draft_order = determine_draft_order(users)
      assigned_count = assign_picks_in_snake_order(draft_order)

      { success: true, tournament: @tournament, draft_order: draft_order, assigned_picks: assigned_count }
    end

    private

    def determine_draft_order(users)
      # Try to find previous tournament with results
      previous_tourn = @tournament_service.previous_tournament_with_results(@tournament)

      if previous_tourn
        # Use previous tournament standings
        get_draft_order_from_tournament(users, previous_tourn)
      elsif @tournament_service.first_tournament_of_year?(@tournament)
        # First tournament of year - use previous year cumulative scores
        get_draft_order_from_previous_year(users)
      else
        # No data available - randomize
        users.shuffle
      end
    end

    def get_draft_order_from_tournament(users, tournament)
      # Get match results for the tournament
      results = MatchResult.where(tournament: tournament, user: users).includes(:user)

      # Group by place to handle ties
      results_by_place = results.group_by(&:place)

      # Build draft order: 4th place picks 1st, 3rd picks 2nd, 2nd picks 3rd, 1st picks 4th
      draft_order = []
      [ 4, 3, 2, 1 ].each do |place|
        users_at_place = results_by_place[place] || []

        if users_at_place.length > 1
          # Apply tie-breaking
          sorted_users = apply_tiebreaker(users_at_place.map(&:user), tournament)
          draft_order.concat(sorted_users)
        elsif users_at_place.length == 1
          draft_order << users_at_place.first.user
        end
      end

      # Handle any users without results (shouldn't happen but defensive)
      users_without_results = users - draft_order
      draft_order.concat(users_without_results.shuffle) if users_without_results.any?

      draft_order
    end

    def get_draft_order_from_previous_year(users)
      previous_year = @tournament.year - 1

      # Get all match results from previous year
      previous_year_results = MatchResult.where(user: users)
                                         .joins(:tournament)
                                         .where(tournaments: { year: previous_year })

      # Sum total scores for each user
      user_cumulative_scores = {}
      users.each do |user|
        user_results = previous_year_results.where(user: user)
        user_cumulative_scores[user] = user_results.sum(:total_score)
      end

      # Sort by cumulative score (lowest is best)
      # Reverse so worst (highest score) picks first
      users.sort_by { |user| -user_cumulative_scores[user] }
    end

    def apply_tiebreaker(tied_users, tournament)
      winner_golfer_id = find_tournament_winner_golfer_id(tournament)

      user_data = tied_users.index_by(&:id).transform_values do |user|
        build_tiebreaker_data(user, tournament, winner_golfer_id)
      end

      tied_users.sort do |user_a, user_b|
        result = BusinessLogic::TiebreakerService.compare(user_data[user_a.id], user_data[user_b.id])
        result == 0 ? user_a.id <=> user_b.id : result
      end
    end

    def find_tournament_winner_golfer_id(tournament)
      snapshot = LeaderboardSnapshot.find_by(tournament: tournament)
      return nil unless snapshot&.leaderboard_data

      winner_data = snapshot.leaderboard_data.find { |p| p["position"] == "1" }
      return nil unless winner_data

      Golfer.find_by(source_id: winner_data["player_id"])&.id
    end

    def build_tiebreaker_data(user, tournament, winner_golfer_id)
      picks = MatchPick.where(user: user, tournament: tournament, drafted: true).includes(:scores)
      golfer_totals = picks.map { |p| p.scores.sum(&:score) }.sort
      drafted_winner = winner_golfer_id.present? && picks.any? { |p| p.golfer_id == winner_golfer_id }
      { golfer_totals: golfer_totals, drafted_winner: drafted_winner }
    end

    def assign_picks_in_snake_order(draft_order)
      already_drafted_golfers = Set.new
      assigned_count = 0

      # Create snake pattern: [4th, 3rd, 2nd, 1st] + [1st, 2nd, 3rd, 4th] = 8 picks total
      # Each user gets exactly 2 picks
      full_draft_order = draft_order + draft_order.reverse

      full_draft_order.each do |user|
        pick = get_next_available_pick(user, already_drafted_golfers)

        if pick
          pick.update!(drafted: true)
          already_drafted_golfers.add(pick.golfer_id)
          assigned_count += 1
        end
      end

      assigned_count
    end

    def get_next_available_pick(user, already_drafted_golfers)
      # Get user's picks for this tournament, ordered by priority
      picks = MatchPick.where(user: user, tournament: @tournament)
                       .order(:priority)

      # Find first pick where golfer hasn't been drafted yet
      picks.find { |pick| !already_drafted_golfers.include?(pick.golfer_id) }
    end
  end
end
