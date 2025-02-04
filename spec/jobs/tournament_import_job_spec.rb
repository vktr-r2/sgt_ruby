require "rails_helper"

RSpec.describe TournamentImportJob, type: :job do
  let(:tournament_id) { "12345" }
  let(:api_data) { [ { "tournament_id" => tournament_id, "name" => "Test Tournament" } ] }
  let(:tournament_client) { instance_double(RapidApi::TournamentClient, fetch: api_data) }
  let(:tournament_importer) { instance_double(Importers::TournamentImporter, process: true) }

  before do
    allow(ApplicationHelper::TournamentEvaluations).to receive(:determine_current_tourn_id).and_return(tournament_id)
    allow(RapidApi::TournamentClient).to receive(:new).and_return(tournament_client)
    allow(tournament_client).to receive(:fetch).with(tournament_id).and_return(api_data)
    allow(Importers::TournamentImporter).to receive(:new).with(api_data).and_return(tournament_importer)
  end

  it "fetches API data and processes tournament import" do
    described_class.perform_now

    expect(ApplicationHelper::TournamentEvaluations).to have_received(:determine_current_tourn_id)
    expect(tournament_client).to have_received(:fetch).with(tournament_id)
    expect(Importers::TournamentImporter).to have_received(:new).with(api_data)
    expect(tournament_importer).to have_received(:process)
  end

  context "when API data is blank" do
    let(:api_data) { nil }

    it "does not process tournament import" do
      described_class.perform_now

      expect(tournament_client).to have_received(:fetch).with(tournament_id)
      expect(Importers::TournamentImporter).not_to have_received(:new)
    end
  end
end
