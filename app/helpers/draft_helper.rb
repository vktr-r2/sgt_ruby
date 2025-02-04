module DraftHelper
  module GolferData
    def self.get_current_tourn_golfers
      unique_id = ApplicationHelper::TournamentEvaluations.determine_current_tourn_unique_id
      golfers = Golfer.where(last_active_tourney: unique_id)
      golfers
    end

    def self.sort_current_tourn_golfers(golfers)
      sorted_golfers = golfers.sort_by { |golfer| golfer[:l_name] }
      sorted_golfers
    end
  end
end
