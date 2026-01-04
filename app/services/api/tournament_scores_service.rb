module Api
  class TournamentScoresService
    def self.call
      new.call
    end

    def call
      tournament = BusinessLogic::TournamentService.new.current_tournament

      return null_response unless tournament

      {
        tournament: tournament_data(tournament),
        leaderboard: build_leaderboard(tournament)
      }
    end

    private

    def null_response
      { tournament: nil, leaderboard: [] }
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

    def build_leaderboard(tournament)
      User.joins(:match_picks)
          .where(match_picks: { tournament: tournament, drafted: true })
          .distinct
          .includes(match_picks: [ :golfer, :scores ])
          .map { |user| user_leaderboard_entry(user, tournament) }
          .sort_by { |entry| entry[:total_strokes] || Float::INFINITY }
          .each_with_index { |entry, index| entry[:current_position] = index + 1 }
    end

    def user_leaderboard_entry(user, tournament)
      picks = user.match_picks.where(tournament: tournament, drafted: true)
                  .includes(:golfer, :scores)

      {
        user_id: user.id,
        username: user.name,
        total_strokes: calculate_total_strokes(picks),
        current_position: nil, # Set after sorting
        golfers: picks.map { |pick| golfer_data(pick) }
      }
    end

    def golfer_data(pick)
      last_score = pick.scores.order(:round).last

      {
        golfer_id: pick.golfer_id,
        name: "#{pick.golfer.f_name} #{pick.golfer.l_name}",
        total_score: pick.scores.sum(:score),
        position: last_score&.position,
        status: last_score&.status || "active",
        rounds: pick.scores.order(:round).map { |s| round_data(s) },
        was_replaced: pick.original_golfer_id.present?
      }
    end

    def round_data(score)
      {
        round: score.round,
        score: score.score,
        position: score.position
      }
    end

    def calculate_total_strokes(picks)
      total = picks.sum { |pick| pick.scores.sum(:score) }
      total.positive? ? total : nil
    end
  end
end
