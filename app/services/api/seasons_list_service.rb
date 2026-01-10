module Api
  class SeasonsListService
    def self.call
      new.call
    end

    def call
      { seasons: build_seasons_list }
    end

    private

    def build_seasons_list
      completed_years.map { |year| build_season_summary(year) }
    end

    def completed_years
      Tournament.where("end_date < ?", Date.current)
                .distinct
                .pluck(:year)
                .sort
                .reverse
    end

    def build_season_summary(year)
      standings = calculate_standings(year)

      {
        year: year,
        tournament_count: Tournament.where(year: year).count,
        season_winner: format_winner(standings.first),
        standings_preview: standings.map { |s| preview_format(s) },
        majors_won: calculate_majors_leader(year),
        total_winners_picked: aggregate_winners_picked(year),
        total_cuts_missed: aggregate_cuts_missed(year)
      }
    end

    def calculate_standings(year)
      # Reuse existing SeasonStandingsService
      Api::SeasonStandingsService.call(year)[:standings]
    end

    def format_winner(standing)
      return nil unless standing

      {
        user_id: standing[:user_id],
        username: standing[:username],
        total_points: standing[:total_points]
      }
    end

    def preview_format(standing)
      {
        rank: standing[:rank],
        username: standing[:username],
        total_points: standing[:total_points]
      }
    end

    def calculate_majors_leader(year)
      # Query user with most major wins for this year
      result = MatchResult.joins(:tournament)
                          .where(place: 1)
                          .where("tournaments.major_championship = ?", true)
                          .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", year)
                          .group(:user_id)
                          .select('user_id, COUNT(*) as count')
                          .order('count DESC')
                          .first

      return nil unless result

      user = User.find(result.user_id)
      {
        user_id: user.id,
        username: user.name,
        count: result.count
      }
    end

    def aggregate_winners_picked(year)
      MatchResult.joins(:tournament)
                 .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", year)
                 .where(winner_picked: true)
                 .count
    end

    def aggregate_cuts_missed(year)
      MatchResult.joins(:tournament)
                 .where("EXTRACT(YEAR FROM tournaments.start_date) = ?", year)
                 .sum(:cuts_missed)
    end
  end
end
