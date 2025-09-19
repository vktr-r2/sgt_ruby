class UpdateLeaderboardJob < ApplicationJob
  queue_as :default

  def perform
    setup
    api_data = RapidApi::LeaderboardClient.new.fetch(@tournament_service.current_tournament_id)
    return nil if api_data.blank?

    Importers::LeaderboardImporter.new(api_data).process
  end

  def setup
    @leaderboard_service = BusinessLogic::LeaderboardService.new
  end
end