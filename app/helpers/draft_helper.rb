module DraftHelper
  module GolferData
    def self.get_current_tourn_golfers
      unique_id = ApplicationHelper::TournamentEvaluations.determine_current_tourn_unique_id
      golfers = Golfer.where(last_active_tourney: unique_id)
      sort_golfers(golfers)
    end

    def self.sort_golfers(golfers)
      sorted_golfers = golfers.sort_by { |golfer| golfer[:l_name] }
      sorted_golfers
    end
  end

  module PickData
    def self.get_users_picks_for_tourn(user_id)
      tournament = ApplicationHelper::TournamentEvaluations.determine_current_tournament
      picks = MatchPick.where(
        user_id: user_id,
        tournament_id: tournament.id
        )
      picks
    end
  end
end
