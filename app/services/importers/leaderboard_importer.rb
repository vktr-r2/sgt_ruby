module Importers
  # LeaderboardImporter takes leaderboard API data and creates/updates Score records
  # for drafted golfers. One score entry per golfer per round.
  class LeaderboardImporter
    def initialize(leaderboard_data, tournament)
      @leaderboard_data = leaderboard_data
      @tournament = tournament
      @current_round = determine_current_round
    end

    def process
      return unless @leaderboard_data && @leaderboard_data["leaderboardRows"]

      # STEP 1: Detect and replace WD golfers BEFORE processing scores
      wd_service = BusinessLogic::WdReplacementService.new(@tournament, @current_round)
      wd_service.detect_and_replace_wd_golfers(@leaderboard_data)

      # STEP 2: Process scores for all golfers (including replacements)
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

      # Extract position and status
      player_position = player_data["position"]
      player_status = player_data["status"]

      # Handle cut players (WD players already replaced in step 1)
      if player_status == "cut"
        handle_cut_player(match_pick, player_data, player_status, player_position)
      else
        save_round_scores(match_pick, player_data, player_status, player_position)
      end
    end

    def save_round_scores(match_pick, player_data, player_status, player_position)
      rounds = player_data["rounds"] || []
      current_round_num = extract_int_from_api(player_data["currentRound"])
      round_complete = player_data["roundComplete"]

      # Save completed rounds from rounds array
      rounds.each do |round_data|
        round_number = extract_int_from_api(round_data["roundId"])
        strokes = extract_int_from_api(round_data["strokes"])

        next unless round_number && strokes
        next unless round_number.between?(1, 4)

        save_single_round(match_pick, round_number, strokes, player_status, player_position)
      end

      # Check if current round is in progress (not in rounds array yet)
      return unless current_round_num && current_round_num.between?(1, 4)
      return if round_complete # Round is complete, should be in rounds array

      # Check if current round already exists in rounds array
      current_round_in_array = rounds.any? do |r|
        extract_int_from_api(r["roundId"]) == current_round_num
      end
      return if current_round_in_array

      # Save in-progress round using currentRoundScore
      in_progress_strokes = convert_score_to_par_to_strokes(player_data["currentRoundScore"])
      return unless in_progress_strokes

      save_single_round(match_pick, current_round_num, in_progress_strokes, player_status, player_position)
      Rails.logger.info "Saved in-progress round #{current_round_num} score: #{in_progress_strokes} strokes (match_pick_id: #{match_pick.id})"
    end

    def save_single_round(match_pick, round_number, strokes, player_status, player_position)
      score = Score.find_or_initialize_by(
        match_pick: match_pick,
        round: round_number
      )

      # If this is a replacement and score already exists from original golfer, preserve it
      if match_pick.original_golfer_id.present? && !score.new_record?
        Rails.logger.info "Preserving original golfer's score for round #{round_number} (match_pick_id: #{match_pick.id})"
        return
      end

      score.score = strokes
      score.status = player_status
      score.position = player_position
      save_score(score)
    end

    # Convert score-to-par string ("-3", "+2", "E") to strokes
    # Assumes par 72 per round
    def convert_score_to_par_to_strokes(score_to_par)
      return nil unless score_to_par

      par = @tournament.par || 72

      if score_to_par == "E"
        par
      elsif score_to_par.start_with?("+")
        par + score_to_par[1..].to_i
      elsif score_to_par.start_with?("-")
        par - score_to_par[1..].to_i
      else
        # Handle plain number (could be positive or negative)
        par + score_to_par.to_i
      end
    end

    def handle_cut_player(match_pick, player_data, player_status, player_position)
      rounds = player_data["rounds"] || []

      # Save actual scores for rounds played
      rounds.each do |round_data|
        round_number = extract_int_from_api(round_data["roundId"])
        strokes = extract_int_from_api(round_data["strokes"])

        next unless round_number && strokes
        next unless round_number.between?(1, 4)

        score = Score.find_or_initialize_by(
          match_pick: match_pick,
          round: round_number
        )
        score.score = strokes
        score.status = player_status
        score.position = player_position
        save_score(score)
      end

      # Copy scores for missed rounds (day 1 to day 3, day 2 to day 4)
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

      # Create new score for target round (copy score, position, and status)
      Score.create!(
        match_pick: match_pick,
        round: to_round,
        score: source_score.score,
        position: source_score.position,
        status: source_score.status
      )

      Rails.logger.info "Copied round #{from_round} score to round #{to_round} for cut player (match_pick_id: #{match_pick.id})"
    end

    def determine_current_round
      # Try to get current round from top-level API data first
      if @leaderboard_data && @leaderboard_data["roundId"]
        round_from_api = extract_int_from_api(@leaderboard_data["roundId"])
        return round_from_api if round_from_api
      end

      # Fallback to checking player rounds
      max_round = 1
      return max_round unless @leaderboard_data && @leaderboard_data["leaderboardRows"]

      @leaderboard_data["leaderboardRows"].each do |player|
        next unless player["rounds"]

        player["rounds"].each do |round_data|
          round_num = extract_int_from_api(round_data["roundId"])
          max_round = [ max_round, round_num ].max if round_num
        end
      end

      max_round
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
