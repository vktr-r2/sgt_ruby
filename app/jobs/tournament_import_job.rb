class TournamentImportJob < ApplicationJob
  queue_as :default

  def perform
    api_data = RapidApi::TournamentClient.new.fetch(ApplicationHelper::TournamentEvaluations.determine_current_tourn_id)
    nil if api_data.blank?

  Importers::TournamentImporter.new(api_data).process
  end
end
