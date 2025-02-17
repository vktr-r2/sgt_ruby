module BusinessLogic
  class GolferService
    def initialize
      @tournament_evaluator = BusinessLogic::TournamentService.new
    end

    def get_current_tourn_golfers
      unique_id = @tournament_evaluator.current_tournament_unique_id
      golfers = Golfer.where(last_active_tourney: unique_id)
      sort_golfers(golfers)
    end

    def sort_golfers(golfers)
      sorted_golfers = golfers.sort_by { |golfer| golfer[:l_name] }
      sorted_golfers
    end
  end
end
