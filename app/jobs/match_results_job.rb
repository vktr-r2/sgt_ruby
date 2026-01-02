class MatchResultsJob < ApplicationJob
  queue_as :default

  def perform
    setup
    # Get previous tournament (tournament that just completed)
    tournament = @tournament_service.previous_tournament

    return nil if tournament.blank?

    # Calculate and store match results
    BusinessLogic::MatchResultsCalculationService.new(tournament).calculate
    Rails.logger.info "Match results calculated successfully for #{tournament.name}"
  end

  def setup
    @tournament_service = BusinessLogic::TournamentService.new
  end
end
