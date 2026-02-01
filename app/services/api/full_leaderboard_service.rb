module Api
  class FullLeaderboardService
    def self.call
      new.call
    end

    def call
      tournament = BusinessLogic::TournamentService.new.current_tournament
      return null_response unless tournament

      snapshot = LeaderboardSnapshot.find_by(tournament_id: tournament.id)
      return null_response unless snapshot&.leaderboard_data.present?

      drafted_golfer_info = get_drafted_golfer_info(tournament)

      {
        tournament: tournament_data(tournament),
        current_round: snapshot.current_round,
        cut_line: build_cut_line(snapshot),
        fetched_at: snapshot.fetched_at&.iso8601,
        players: build_players_list(snapshot.leaderboard_data, drafted_golfer_info)
      }
    end

    private

    def null_response
      { tournament: nil, current_round: nil, cut_line: nil, fetched_at: nil, players: [] }
    end

    def tournament_data(tournament)
      {
        id: tournament.id,
        name: tournament.name,
        par: tournament.par || 72
      }
    end

    def get_drafted_golfer_info(tournament)
      MatchPick.where(tournament: tournament, drafted: true)
               .joins(:golfer, :user)
               .pluck("golfers.source_id", "users.name")
               .to_h
    end

    def build_cut_line(snapshot)
      return nil unless snapshot.cut_line_score.present?

      {
        score: snapshot.cut_line_score,
        count: snapshot.cut_line_count
      }
    end

    def build_players_list(leaderboard_data, drafted_info)
      players = leaderboard_data.map do |player|
        player_with_drafter_info(player, drafted_info)
      end

      # Sort by position
      players.sort_by { |p| parse_position_for_sort(p[:position]) }
    end

    def player_with_drafter_info(player, drafted_info)
      {
        player_id: player["player_id"],
        name: player["name"],
        position: player["position"],
        status: player["status"],
        total_strokes: player["total_strokes"],
        total_to_par: player["total_to_par"],
        thru: player["thru"],
        rounds: player["rounds"]&.map { |r| { round: r["round"], score: r["score"], in_progress: r["in_progress"] } } || [],
        drafted_by: drafted_info[player["player_id"]]
      }
    end

    def parse_position_for_sort(position)
      return [ Float::INFINITY, 0 ] unless position

      # Handle special cases
      return [ Float::INFINITY, 1 ] if position.to_s.upcase == "CUT"
      return [ Float::INFINITY, 2 ] if position.to_s.upcase == "WD"
      return [ Float::INFINITY, 3 ] if position.to_s.upcase == "DQ"

      # Handle tied positions like "T5" or regular "5"
      numeric_part = position.to_s.gsub(/[^\d]/, "").to_i
      is_tied = position.to_s.upcase.start_with?("T")

      [ numeric_part, is_tied ? 1 : 0 ]
    end
  end
end
