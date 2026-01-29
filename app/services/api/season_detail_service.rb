module Api
  class SeasonDetailService
    class UnprocessableError < StandardError; end

    def self.call(year)
      new(year).call
    end

    def initialize(year)
      @year = year
    end

    def call
      raise UnprocessableError, "No data for season #{@year}" unless season_exists?

      {
        season_year: @year,
        tournament_count: tournaments.count,
        standings: build_enhanced_standings,
        tournaments: build_tournaments_with_winners
      }
    end

    private

    def season_exists?
      Tournament.where(year: @year).exists?
    end

    def tournaments
      @tournaments ||= Tournament.where(year: @year)
                                 .order(start_date: :asc)
                                 .includes(match_results: :user)
    end

    def build_enhanced_standings
      base_standings = Api::SeasonStandingsService.call(@year)[:standings]

      base_standings.map do |standing|
        standing.merge(majors_won: count_user_majors(standing[:user_id]))
      end
    end

    def count_user_majors(user_id)
      MatchResult.joins(:tournament)
                 .where(user_id: user_id, place: 1)
                 .where("tournaments.major_championship = ?", true)
                 .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", @year)
                 .count
    end

    def build_tournaments_with_winners
      tournaments.map do |tournament|
        winner = tournament.match_results.find_by(place: 1)

        {
          id: tournament.id,
          name: tournament.name,
          start_date: tournament.start_date.to_s,
          end_date: tournament.end_date.to_s,
          is_major: tournament.major_championship,
          winner: winner ? format_winner_info(winner) : nil
        }
      end
    end

    def format_winner_info(match_result)
      {
        user_id: match_result.user_id,
        username: match_result.user.name,
        total_points: match_result.total_score,
        place: match_result.place
      }
    end
  end
end
