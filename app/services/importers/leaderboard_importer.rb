module Importers
  # LeaderboardImporter takes leaderboard API data and creates/updates Score records
  # for drafted golfers. One score entry per golfer per round.
  class LeaderboardImporter
    def initialize(leaderboard_data, tournament)
      @leaderboard_data = leaderboard_data
      @tournament = tournament
    end

    def process
      return unless @leaderboard_data && @leaderboard_data["leaderboardRows"]

      # Get all drafted match picks for this tournament
      drafted_picks = MatchPick.where(tournament: @tournament, drafted: true)
                               .includes(:golfer)

      @leaderboard_data["leaderboardRows"].each do |player_data|
        process_player_scores(player_data, drafted_picks)
      end
    end

    private

    def process_player_scores(player_data, drafted_picks)
      player_id = player_data["playerId"]

      # Find the match_pick for this golfer
      match_pick = drafted_picks.find { |pick| pick.golfer.source_id == player_id }
      return unless match_pick

      # Check if player was cut
      was_cut = player_data["status"] == "cut" || player_data["status"] == "wd"

      if was_cut
        handle_cut_player(match_pick, player_data)
      else
        save_round_scores(match_pick, player_data["rounds"])
      end
    end

    def save_round_scores(match_pick, rounds)
      return unless rounds

      rounds.each do |round_data|
        # Extract round number from RapidAPI's MongoDB format
        round_number = extract_int_from_api(round_data["roundId"])
        strokes = extract_int_from_api(round_data["strokes"])

        next unless round_number && strokes

        # Find existing score or create new one (first API call creates, second updates)
        score = Score.find_or_initialize_by(
          match_pick: match_pick,
          round: round_number
        )

        score.score = strokes
        save_score(score)
      end
    end

    def handle_cut_player(match_pick, player_data)
      rounds = player_data["rounds"] || []

      # Save actual scores for rounds played
      rounds.each do |round_data|
        round_number = extract_int_from_api(round_data["roundId"])
        strokes = extract_int_from_api(round_data["strokes"])

        next unless round_number && strokes

        score = Score.find_or_initialize_by(
          match_pick: match_pick,
          round: round_number
        )
        score.score = strokes
        save_score(score)
      end

      # Copy scores for missed rounds (day 1 ’ day 3, day 2 ’ day 4)
      copy_score_if_missing(match_pick, from_round: 1, to_round: 3)
      copy_score_if_missing(match_pick, from_round: 2, to_round: 4)
    end

    def copy_score_if_missing(match_pick, from_round:, to_round:)
      # Check if the target round already has a score
      existing_score = Score.find_by(match_pick: match_pick, round: to_round)
      return if existing_score

      # Find the source round score
      source_score = Score.find_by(match_pick: match_pick, round: from_round)
      return unless source_score

      # Create new score for target round
      Score.create!(
        match_pick: match_pick,
        round: to_round,
        score: source_score.score
      )

      Rails.logger.info "Copied round #{from_round} score to round #{to_round} for cut player (match_pick_id: #{match_pick.id})"
    end

    def save_score(score)
      begin
        if score.save
          Rails.logger.info "Score saved: Round #{score.round}, #{score.score} strokes (match_pick_id: #{score.match_pick_id})"
        else
          Rails.logger.error "Validation failed for score: #{score.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        Rails.logger.error "Error saving score: #{e.message}"
      end
    end

    # RapidAPI returns MongoDB-formatted integers: {"$numberInt"=>"70"}
    # Extract the actual integer value for PostgreSQL storage
    def extract_int_from_api(value)
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
