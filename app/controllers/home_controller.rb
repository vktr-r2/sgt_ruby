class HomeController < ApplicationController
  def index
    tournament_service = BusinessLogic::TournamentService.new
    current_tournament = tournament_service.current_tournament
    draft_window_service = BusinessLogic::DraftWindowService.new(current_tournament)
    recently_completed = current_tournament.nil? ? tournament_service.recently_completed_tournament : nil

    render json: {
      current_tournament: current_tournament ? current_tournament_payload(current_tournament, draft_window_service) : nil,
      recently_completed_tournament: recently_completed ? recently_completed_payload(recently_completed) : nil,
      app_info: { name: "Spreadsheet Golf Tour", version: "1.0.0" }
    }
  end

  private

  def current_tournament_payload(tournament, draft_window_service)
    {
      id: tournament.id,
      name: tournament.name,
      start_date: tournament.start_date,
      end_date: tournament.end_date,
      week_number: tournament.week_number,
      year: tournament.year,
      format: tournament.format,
      draft_window: {
        start: tournament.draft_window_start,
        end: tournament.draft_window_end,
        status: draft_window_service.draft_window_status,
        is_open: draft_window_service.draft_open?
      }
    }
  end

  def recently_completed_payload(tournament)
    {
      id: tournament.id,
      name: tournament.name,
      end_date: tournament.end_date,
      is_major: tournament.major_championship
    }
  end
end
