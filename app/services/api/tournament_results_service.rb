module Api
  class TournamentResultsService
    class UnprocessableError < StandardError; end

    def self.call(tournament_id)
      new(tournament_id).call
    end

    def initialize(tournament_id)
      @tournament_id = tournament_id
    end

    def call
      tournament = Tournament.find(@tournament_id)

      raise UnprocessableError, "Tournament not complete" unless completed?(tournament)

      {
        tournament: tournament_data(tournament),
        results: build_results(tournament)
      }
    end

    private

    def completed?(tournament)
      tournament.end_date < Date.current
    end

    def tournament_data(tournament)
      {
        id: tournament.id,
        name: tournament.name,
        start_date: tournament.start_date.to_s,
        end_date: tournament.end_date.to_s,
        is_major: tournament.major_championship
      }
    end

    def build_results(tournament)
      tournament.match_results
                .includes(user: { match_picks: [ :golfer, :scores ] })
                .order(:place)
                .map { |result| result_entry(result, tournament) }
    end

    def result_entry(match_result, tournament)
      picks = match_result.user.match_picks.where(tournament: tournament, drafted: true)
                                          .includes(:golfer, :scores)

      {
        place: match_result.place,
        user_id: match_result.user_id,
        username: match_result.user.name,
        total_points: match_result.total_score,
        total_strokes: picks.sum { |p| p.scores.sum(:score) },
        winner_picked: match_result.winner_picked,
        cuts_missed: match_result.cuts_missed,
        golfers: picks.map { |pick| completed_golfer_data(pick) }
      }
    end

    def completed_golfer_data(pick)
      final_score = pick.scores.order(:round).last

      {
        golfer_id: pick.golfer_id,
        name: "#{pick.golfer.f_name} #{pick.golfer.l_name}",
        total_score: pick.scores.sum(:score),
        final_position: final_score&.position,
        status: final_score&.status || "complete",
        was_replaced: pick.original_golfer_id.present?
      }
    end
  end
end
