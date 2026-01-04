module Api
  class TournamentsController < Api::BaseController
    before_action :authenticate_api_user!

    def current_scores
      result = Api::TournamentScoresService.call
      render_success(result)
    end
  end
end
