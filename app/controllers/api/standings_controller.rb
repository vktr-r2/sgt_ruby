module Api
  class StandingsController < Api::BaseController
    before_action :authenticate_api_user!

    # EXISTING - Keep for backward compatibility
    def season
      year = params[:year]&.to_i
      result = Api::SeasonStandingsService.call(year)
      render_success(result)
    end

    # NEW - All seasons list
    def seasons
      result = Api::SeasonsListService.call
      render_success(result)
    end

    # NEW - Specific season with tournaments
    def season_detail
      year = params[:year].to_i
      result = Api::SeasonDetailService.call(year)
      render_success(result)
    rescue Api::SeasonDetailService::UnprocessableError => e
      render_error(e.message, :unprocessable_entity)
    end
  end
end
