class LeaderboardImportJob < ApplicationJob
  queue_as :default

  def perform
    setup
    tournament = @tournament_service.current_tournament
    return nil if tournament.blank?

    api_data = RapidApi::LeaderboardClient.new.fetch(tournament.tournament_id)
    return nil if api_data.blank?

    Importers::LeaderboardImporter.new(api_data, tournament).process
    Rails.logger.info "Leaderboard data imported successfully for #{tournament.name}"
  end

  def setup
    @tournament_service = BusinessLogic::TournamentService.new
  end
end
