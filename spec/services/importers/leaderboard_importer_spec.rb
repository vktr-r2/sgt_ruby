require "rails_helper"

RSpec.describe Importers::LeaderboardImporter do
  let(:tournament) { create(:tournament, tournament_id: "464", name: "Test Tournament") }
  let(:user) { create(:user) }
  let(:golfer) { create(:golfer, source_id: "46046", f_name: "Scottie", l_name: "Scheffler") }
  let(:match_pick) { create(:match_pick, user: user, tournament: tournament, golfer: golfer, drafted: true) }

  let(:leaderboard_data) do
    {
      "leaderboardRows" => [
        {
          "playerId" => "46046",
          "firstName" => "Scottie",
          "lastName" => "Scheffler",
          "status" => "complete",
          "rounds" => [
            { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } },
            { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "68" } }
          ]
        }
      ]
    }
  end

  describe "#process" do
    it "creates score records for drafted golfer" do
      match_pick # Ensure match_pick exists

      importer = described_class.new(leaderboard_data, tournament)
      importer.process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(2)
      expect(scores.first.round).to eq(1)
      expect(scores.first.score).to eq(70)
      expect(scores.second.round).to eq(2)
      expect(scores.second.score).to eq(68)
    end
  end
end
