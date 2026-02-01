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

  context "when API data is blank" do
    let(:api_data) { nil }

    it "does not process leaderboard import" do
      described_class.perform_now

      expect(leaderboard_client).to have_received(:fetch).with(tournament.tournament_id)
      expect(Importers::LeaderboardImporter).not_to have_received(:new)
    end
  end

  describe "leaderboard snapshot saving" do
    let(:api_data) do
      {
        "leaderboardRows" => [
          {
            "playerId" => "123",
            "firstName" => "Tiger",
            "lastName" => "Woods",
            "position" => "1",
            "status" => "active",
            "thru" => "F",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "68" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "70" } }
            ]
          },
          {
            "playerId" => "456",
            "firstName" => "Rory",
            "lastName" => "McIlroy",
            "position" => "T2",
            "status" => "active",
            "thru" => "F",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } }
            ]
          }
        ],
        "roundId" => { "$numberInt" => "2" },
        "cutLines" => [
          { "cutScore" => "-3", "cutCount" => { "$numberInt" => "73" } }
        ]
      }
    end

    it "saves a leaderboard snapshot after processing" do
      expect {
        described_class.perform_now
      }.to change(LeaderboardSnapshot, :count).by(1)
    end

    it "saves the correct round number" do
      described_class.perform_now

      snapshot = LeaderboardSnapshot.last
      expect(snapshot.current_round).to eq(2)
    end

    it "saves cut line information" do
      described_class.perform_now

      snapshot = LeaderboardSnapshot.last
      expect(snapshot.cut_line_score).to eq("-3")
      expect(snapshot.cut_line_count).to eq(73)
    end

    it "saves player data with correct structure" do
      described_class.perform_now

      snapshot = LeaderboardSnapshot.last
      tiger = snapshot.leaderboard_data.find { |p| p["player_id"] == "123" }

      expect(tiger["name"]).to eq("Tiger Woods")
      expect(tiger["position"]).to eq("1")
      expect(tiger["status"]).to eq("active")
      expect(tiger["rounds"].length).to eq(2)
    end

    it "calculates total strokes correctly" do
      described_class.perform_now

      snapshot = LeaderboardSnapshot.last
      tiger = snapshot.leaderboard_data.find { |p| p["player_id"] == "123" }

      expect(tiger["total_strokes"]).to eq(138) # 68 + 70
    end

    it "calculates total to par correctly" do
      described_class.perform_now

      snapshot = LeaderboardSnapshot.last
      tiger = snapshot.leaderboard_data.find { |p| p["player_id"] == "123" }

      # 138 strokes - (72 par * 2 rounds) = 138 - 144 = -6
      expect(tiger["total_to_par"]).to eq(-6)
    end

    context "when leaderboardRows is empty" do
      let(:api_data) { { "leaderboardRows" => [] } }

      it "does not save a snapshot" do
        expect {
          described_class.perform_now
        }.not_to change(LeaderboardSnapshot, :count)
      end
    end

    context "with in-progress round score" do
      let(:api_data) do
        {
          "leaderboardRows" => [
            {
              "playerId" => "123",
              "firstName" => "Tiger",
              "lastName" => "Woods",
              "position" => "1",
              "status" => "active",
              "currentRound" => { "$numberInt" => "2" },
              "currentRoundScore" => "-3",
              "roundComplete" => false,
              "rounds" => [
                { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } }
              ]
            }
          ],
          "roundId" => { "$numberInt" => "2" }
        }
      end

      it "includes in-progress round score" do
        described_class.perform_now

        snapshot = LeaderboardSnapshot.last
        tiger = snapshot.leaderboard_data.find { |p| p["player_id"] == "123" }
        round2 = tiger["rounds"].find { |r| r["round"] == 2 }

        expect(round2).to be_present
        expect(round2["score"]).to eq(69) # par 72 - 3 = 69
        expect(round2["in_progress"]).to be true
      end
    end
  end
end
