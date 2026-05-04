class MatchResultsJob < ApplicationJob
  queue_as :default

  def perform(tournament_id = nil)
    setup
    tournament = find_tournament(tournament_id)

    return nil if tournament.blank?

    if tournament.match_results.exists?
      Rails.logger.info "Match results already exist for #{tournament.name}, skipping"
      return nil
    end

    BusinessLogic::MatchResultsCalculationService.new(tournament).calculate
    tournament.update_column(:concluded, true)
    Rails.logger.info "Match results calculated and tournament concluded: #{tournament.name}"
  rescue StandardError => e
    Rails.logger.error "MatchResultsJob failed for tournament #{tournament&.name}: #{e.message}"
    raise
  end

  private

  def setup
    @tournament_service = BusinessLogic::TournamentService.new
  end

  def find_tournament(tournament_id)
    return Tournament.find(tournament_id) if tournament_id.present?

    @tournament_service.previous_tournament
  end
end
