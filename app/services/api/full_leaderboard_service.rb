module Api
  class FullLeaderboardService
    def self.call
      new.call
    end

    def call
      tournament = BusinessLogic::TournamentService.new.current_tournament
      return null_response unless tournament

      leaderboard_data = fetch_leaderboard(tournament.unique_id)
      return null_response unless leaderboard_data && leaderboard_data["leaderboardRows"]

      drafted_golfer_ids = get_drafted_golfer_ids(tournament)

      {
        tournament: tournament_data(tournament),
        current_round: extract_int(leaderboard_data["roundId"]),
        cut_line: extract_cut_line(leaderboard_data),
        players: build_players_list(leaderboard_data, drafted_golfer_ids, tournament)
      }
    end

    private

    def null_response
      { tournament: nil, current_round: nil, cut_line: nil, players: [] }
    end

    def fetch_leaderboard(tourn_id)
      client = RapidApi::LeaderboardClient.new
      client.fetch(tourn_id)
    rescue StandardError => e
      Rails.logger.error "Failed to fetch leaderboard: #{e.message}"
      nil
    end

    def tournament_data(tournament)
      {
        id: tournament.id,
        name: tournament.name,
        par: tournament.par || 72
      }
    end

    def get_drafted_golfer_ids(tournament)
      MatchPick.where(tournament: tournament, drafted: true)
               .joins(:golfer)
               .pluck("golfers.source_id")
               .to_set
    end

    def extract_cut_line(data)
      return nil unless data["cutLines"].present?

      cut_data = data["cutLines"].first
      return nil unless cut_data

      {
        score: cut_data["cutScore"],
        count: extract_int(cut_data["cutCount"])
      }
    end

    def build_players_list(data, drafted_ids, tournament)
      players = data["leaderboardRows"].map do |player|
        build_player_entry(player, drafted_ids, tournament)
      end

      # Sort by position (numeric comparison, handle ties like "T5")
      players.sort_by { |p| parse_position_for_sort(p[:position]) }
    end

    def build_player_entry(player, drafted_ids, tournament)
      player_id = player["playerId"]
      rounds = player["rounds"] || []
      current_round_num = extract_int(player["currentRound"])
      round_complete = player["roundComplete"]

      # Build rounds array
      round_scores = build_round_scores(rounds, player, current_round_num, round_complete, tournament)

      # Calculate total strokes
      total_strokes = round_scores.sum { |r| r[:score] || 0 }
      total_strokes = nil if total_strokes.zero? && round_scores.empty?

      # Calculate total to par
      rounds_played = round_scores.count { |r| r[:score].present? }
      par_per_round = tournament.par || 72
      total_to_par = rounds_played.positive? ? total_strokes - (par_per_round * rounds_played) : nil

      {
        player_id: player_id,
        name: "#{player['firstName']} #{player['lastName']}".strip,
        position: player["position"],
        status: player["status"],
        total_strokes: total_strokes,
        total_to_par: total_to_par,
        thru: player["thru"],
        rounds: round_scores,
        is_drafted: drafted_ids.include?(player_id)
      }
    end

    def build_round_scores(rounds, player, current_round_num, round_complete, tournament)
      round_scores = []

      # Add completed rounds
      rounds.each do |round_data|
        round_num = extract_int(round_data["roundId"])
        next unless round_num && round_num.between?(1, 4)

        round_scores << {
          round: round_num,
          score: extract_int(round_data["strokes"])
        }
      end

      # Add in-progress round if not in rounds array
      if current_round_num && current_round_num.between?(1, 4) && !round_complete
        existing = round_scores.find { |r| r[:round] == current_round_num }
        unless existing
          in_progress_score = convert_score_to_par_to_strokes(player["currentRoundScore"], tournament)
          if in_progress_score
            round_scores << {
              round: current_round_num,
              score: in_progress_score,
              in_progress: true
            }
          end
        end
      end

      # Sort by round number
      round_scores.sort_by { |r| r[:round] }
    end

    def convert_score_to_par_to_strokes(score_to_par, tournament)
      return nil unless score_to_par

      par = tournament.par || 72

      if score_to_par == "E"
        par
      elsif score_to_par.to_s.start_with?("+")
        par + score_to_par[1..].to_i
      elsif score_to_par.to_s.start_with?("-")
        par - score_to_par[1..].to_i
      else
        par + score_to_par.to_i
      end
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

    def extract_int(value)
      return nil unless value

      if value.is_a?(Hash) && value["$numberInt"]
        value["$numberInt"].to_i
      elsif value.is_a?(Integer)
        value
      else
        value.to_i
      end
    end
  end
end
