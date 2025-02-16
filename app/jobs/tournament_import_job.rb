class TournamentImportJob < ApplicationJob
  queue_as :default

  def initialize
    @tournament_service = BusinessLogic::TournamentService.new
  end

  def perform
    api_data = RapidApi::TournamentClient.new.fetch(tournament_service.current_tournament_id)
    return nil if api_data.blank?

    Importers::TournamentImporter.new(api_data).process
  end
end
