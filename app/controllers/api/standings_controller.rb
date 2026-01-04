module Api
  class StandingsController < Api::BaseController
    before_action :authenticate_api_user!

    def season
      year = params[:year]&.to_i
      result = Api::SeasonStandingsService.call(year)
      render_success(result)
    end
  end
end
