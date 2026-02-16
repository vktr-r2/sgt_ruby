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
      standings = User.joins(:match_results)
                      .joins("INNER JOIN tournaments ON match_results.tournament_id = tournaments.id")
                      .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", @year)
                      .distinct
                      .includes(match_results: :tournament)
                      .map { |user| user_standing(user) }

      sort_with_tiebreakers(standings)
      assign_ranks_with_ties(standings)
    end

    def sort_with_tiebreakers(standings)
      standings.sort_by! do |s|
        [
          s[:total_points],         # Primary: lower is better (ascending)
          -s[:first_place],         # Tiebreaker 1: more firsts is better (descending)
          -s[:winners_picked],      # Tiebreaker 2: more winners picked is better (descending)
          -s[:second_place],        # Tiebreaker 3: more seconds is better (descending)
          -s[:third_place]          # Tiebreaker 4: more thirds is better (descending)
        ]
      end
    end

    def assign_ranks_with_ties(standings)
      standings.each_with_index do |standing, index|
        if index.zero?
          standing[:rank] = 1
        else
          prev = standings[index - 1]
          if same_tiebreaker_stats?(standing, prev)
            standing[:rank] = prev[:rank]
          else
            standing[:rank] = index + 1
          end
        end
      end
      standings
    end

    def same_tiebreaker_stats?(a, b)
      a[:total_points] == b[:total_points] &&
        a[:first_place] == b[:first_place] &&
        a[:winners_picked] == b[:winners_picked] &&
        a[:second_place] == b[:second_place] &&
        a[:third_place] == b[:third_place]
    end

    def user_standing(user)
      results = user.match_results.joins(:tournament)
                    .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", @year)

      {
        rank: nil, # Set after sorting
        user_id: user.id,
        username: user.name,
        total_points: results.sum(:total_score),
        first_place: results.where(place: 1).count,
        second_place: results.where(place: 2).count,
        third_place: results.where(place: 3).count,
        fourth_place: results.where(place: 4).count,
        majors_won: results.joins(:tournament).where(place: 1, tournaments: { major_championship: true }).count,
        winners_picked: results.where(winner_picked: true).count,
        total_cuts_missed: results.sum(:cuts_missed)
      }
    end
  end
end
