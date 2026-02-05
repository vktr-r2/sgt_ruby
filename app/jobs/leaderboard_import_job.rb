class LeaderboardImportJob < ApplicationJob
  queue_as :default

  def perform
    setup
    tournament = @tournament_service.current_tournament
    return nil if tournament.blank?

    api_data = RapidApi::LeaderboardClient.new.fetch(tournament.tournament_id)
    return nil if api_data.blank?

    # Import scores for drafted players
    Importers::LeaderboardImporter.new(api_data, tournament).process
    Rails.logger.info "Leaderboard data imported successfully for #{tournament.name}"

    # Save full leaderboard snapshot for display
    save_leaderboard_snapshot(tournament, api_data)
  end

  def setup
    @tournament_service = BusinessLogic::TournamentService.new
  end

  private

  def save_leaderboard_snapshot(tournament, api_data)
    return unless api_data["leaderboardRows"].present?

    # Extract cut line info
    cut_line = api_data["cutLines"]&.first
    cut_line_score = cut_line&.dig("cutScore")
    cut_line_count = extract_int(cut_line&.dig("cutCount"))

    # Build player data array
    players = api_data["leaderboardRows"].map do |player|
      build_player_data(player, tournament)
    end

    LeaderboardSnapshot.save_snapshot(
      tournament: tournament,
      leaderboard_data: players,
      current_round: extract_int(api_data["roundId"]),
      cut_line_score: cut_line_score,
      cut_line_count: cut_line_count
    )

    Rails.logger.info "Leaderboard snapshot saved for #{tournament.name} with #{players.size} players"
  rescue StandardError => e
    Rails.logger.error "Failed to save leaderboard snapshot: #{e.message}"
  end

  def build_player_data(player, tournament)
    rounds = player["rounds"] || []
    current_round_num = extract_int(player["currentRound"])
    round_complete = player["roundComplete"]

    # Build rounds array
    round_scores = []
    rounds.each do |round_data|
      round_num = extract_int(round_data["roundId"])
      next unless round_num && round_num.between?(1, 4)

      round_scores << {
        "round" => round_num,
        "score" => extract_int(round_data["strokes"])
      }
    end

    # Add in-progress round if applicable (skip if player hasn't started)
    player_status = player["status"]
    if current_round_num && current_round_num.between?(1, 4) && !round_complete && player_status != "not started"
      existing = round_scores.find { |r| r["round"] == current_round_num }
      unless existing
        in_progress_score = convert_score_to_par_to_strokes(player["currentRoundScore"], tournament)
        if in_progress_score
          round_scores << {
            "round" => current_round_num,
            "score" => in_progress_score,
            "in_progress" => true
          }
        end
      end
    end

    round_scores.sort_by! { |r| r["round"] }

    # Calculate totals
    total_strokes = round_scores.sum { |r| r["score"] || 0 }
    total_strokes = nil if total_strokes.zero? && round_scores.empty?

    rounds_played = round_scores.count { |r| r["score"].present? }
    par_per_round = tournament.par || 72
    total_to_par = rounds_played.positive? ? total_strokes - (par_per_round * rounds_played) : nil

    {
      "player_id" => player["playerId"],
      "name" => "#{player['firstName']} #{player['lastName']}".strip,
      "position" => player["position"],
      "status" => player["status"],
      "total_strokes" => total_strokes,
      "total_to_par" => total_to_par,
      "thru" => player["thru"],
      "rounds" => round_scores
    }
  end

  def convert_score_to_par_to_strokes(score_to_par, tournament)
    return nil if score_to_par.nil? || score_to_par.to_s.strip.empty?

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
