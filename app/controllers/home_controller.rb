class HomeController < ApplicationController
  def index
    tournament_service = BusinessLogic::TournamentService.new
    current_tournament = tournament_service.current_tournament
    draft_window_service = BusinessLogic::DraftWindowService.new(current_tournament)

    render json: {
      current_tournament: current_tournament ? {
        id: current_tournament.id,
        name: current_tournament.name,
        start_date: current_tournament.start_date,
        end_date: current_tournament.end_date,
        week_number: current_tournament.week_number,
        year: current_tournament.year,
        format: current_tournament.format,
        draft_window: {
          start: current_tournament.draft_window_start,
          end: current_tournament.draft_window_end,
          status: draft_window_service.draft_window_status,
          is_open: draft_window_service.draft_open?
        }
      } : nil,
      app_info: {
        name: "Spreadsheet Golf Tour",
        version: "1.0.0"
      }
    }
  end
end
