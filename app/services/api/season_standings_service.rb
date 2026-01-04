module Api
  class SeasonStandingsService
    def self.call(year = nil)
      new(year).call
    end

    def initialize(year = nil)
      @year = year || Date.current.year
    end

    def call
      {
        season_year: @year,
        last_updated: Time.current.iso8601,
        standings: build_standings
      }
    end

    private

    def build_standings
      User.joins(:match_results)
          .joins("INNER JOIN tournaments ON match_results.tournament_id = tournaments.id")
          .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", @year)
          .distinct
          .includes(match_results: :tournament)
          .map { |user| user_standing(user) }
          .sort_by { |standing| standing[:total_points] }
          .each_with_index { |standing, index| standing[:rank] = index + 1 }
    end

    def user_standing(user)
      results = user.match_results.joins(:tournament)
                    .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", @year)

      {
        rank: nil, # Set after sorting
        user_id: user.id,
        username: user.name,
        total_points: results.sum(:total_score),
        tournaments_played: results.count,
        wins: results.where(place: 1).count,
        top_3_finishes: results.where("place <= 3").count,
        winners_picked: results.where(winner_picked: true).count,
        total_cuts_missed: results.sum(:cuts_missed)
      }
    end
  end
end
