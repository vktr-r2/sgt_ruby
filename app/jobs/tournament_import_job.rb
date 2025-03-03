class TournamentImportJob < ApplicationJob
  queue_as :default

  def perform
    setup
    api_data = RapidApi::TournamentClient.new.fetch(@tournament_service.current_tournament_id)
    return nil if api_data.blank?

    Importers::TournamentImporter.new(api_data).process
  end

  def setup
    @tournament_service = BusinessLogic::TournamentService.new
  end
end
