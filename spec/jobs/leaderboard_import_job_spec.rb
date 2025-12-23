require "rails_helper"

RSpec.describe LeaderboardImportJob, type: :job do
  let(:tournament) { create(:tournament, tournament_id: "464", name: "Test Tournament") }
  let(:api_data) { { "leaderboardRows" => [] } }
  let(:leaderboard_client) { instance_double(RapidApi::LeaderboardClient, fetch: api_data) }
  let(:leaderboard_importer) { instance_double(Importers::LeaderboardImporter, process: true) }

  before do
    tournament_service_double = instance_double(BusinessLogic::TournamentService)
    allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service_double)
    allow(tournament_service_double).to receive(:current_tournament).and_return(tournament)

    allow(RapidApi::LeaderboardClient).to receive(:new).and_return(leaderboard_client)
    allow(leaderboard_client).to receive(:fetch).with(tournament.tournament_id).and_return(api_data)
    allow(Importers::LeaderboardImporter).to receive(:new).with(api_data, tournament).and_return(leaderboard_importer)
  end

  it "fetches API data and processes leaderboard import" do
    described_class.perform_now

    expect(BusinessLogic::TournamentService).to have_received(:new)
    expect(leaderboard_client).to have_received(:fetch).with(tournament.tournament_id)
    expect(Importers::LeaderboardImporter).to have_received(:new).with(api_data, tournament)
    expect(leaderboard_importer).to have_received(:process)
  end

  context "when tournament is blank" do
    before do
      tournament_service_double = instance_double(BusinessLogic::TournamentService)
      allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service_double)
      allow(tournament_service_double).to receive(:current_tournament).and_return(nil)
    end

    it "does not fetch leaderboard data" do
      described_class.perform_now

      expect(leaderboard_client).not_to have_received(:fetch)
      expect(Importers::LeaderboardImporter).not_to have_received(:new)
    end
  end
end
