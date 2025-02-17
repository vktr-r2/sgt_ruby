module BusinessLogic
  class DraftService
    def initialize(current_user)
      @current_tournament = BusinessLogic::TournamentService.new.current_tournament
      @current_user = current_user
    end

    def get_user_picks_for_tourn
      tournament = @current_tournament
      picks = MatchPick.where(
        user_id: @current_user.id,
        tournament_id: tournament.id
        )
      picks || []
    end

    def get_draft_review_data
        {
          tournament_name: @current_tournament.name,
          year: Date.today.year,
          picks: get_user_picks_for_tourn
        }
    end
  end
end
