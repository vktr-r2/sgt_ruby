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

    it "updates existing score records on second API call" do
      match_pick # Ensure match_pick exists

      # First API call - create initial scores
      importer = described_class.new(leaderboard_data, tournament)
      importer.process

      # Second API call - golfer's score changed
      updated_data = {
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "firstName" => "Scottie",
            "lastName" => "Scheffler",
            "status" => "complete",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "65" } } # Changed from 68 to 65
            ]
          }
        ]
      }

      importer2 = described_class.new(updated_data, tournament)
      importer2.process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(2) # Still only 2 records
      expect(scores.second.score).to eq(65) # Updated score
    end
  end
end
