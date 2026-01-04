module Api
  class TournamentsController < Api::BaseController
    before_action :authenticate_api_user!

    def current_scores
      result = Api::TournamentScoresService.call
      render_success(result)
    end

    def history
      page = [params[:page]&.to_i || 1, 1].max
      per_page = [[params[:per_page]&.to_i || 10, 50].min, 1].max
      year = params[:year]&.to_i

      query = Tournament.where("end_date < ?", Date.current).order(start_date: :desc)
      query = query.where(year: year) if year.present?

      total_count = query.count
      tournaments = query.limit(per_page).offset((page - 1) * per_page)

      render_success({
        tournaments: tournaments.map { |t| tournament_summary(t) },
        pagination: {
          current_page: page,
          total_pages: (total_count.to_f / per_page).ceil,
          total_count: total_count,
          per_page: per_page
        }
      })
    end

    def show_results
      result = Api::TournamentResultsService.call(params[:id])
      render_success(result)
    rescue ActiveRecord::RecordNotFound
      render_error("Tournament not found", :not_found)
    rescue Api::TournamentResultsService::UnprocessableError => e
      render_error(e.message, :unprocessable_entity)
    end

    private

    def tournament_summary(tournament)
      winner = tournament.match_results.find_by(place: 1)

      {
        id: tournament.id,
        name: tournament.name,
        start_date: tournament.start_date.to_s,
        end_date: tournament.end_date.to_s,
        is_major: tournament.major_championship,
        winner_username: winner&.user&.name,
        winning_score: winner&.total_score
      }
    end
  end
end
