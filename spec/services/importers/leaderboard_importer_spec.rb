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

    it "copies only round 1 to round 3 for cut players on day 3" do
      match_pick # Ensure match_pick exists

      cut_player_data = {
        "roundId" => { "$numberInt" => "3" }, # Day 3 of tournament
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "firstName" => "Scottie",
            "lastName" => "Scheffler",
            "status" => "cut",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "75" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "76" } }
            ]
          }
        ]
      }

      importer = described_class.new(cut_player_data, tournament)
      importer.process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(3) # Rounds 1, 2, and 3 (not 4 yet)
      expect(scores.find_by(round: 1).score).to eq(75)
      expect(scores.find_by(round: 2).score).to eq(76)
      expect(scores.find_by(round: 3).score).to eq(75) # Copied from round 1
      expect(scores.find_by(round: 4)).to be_nil # Not copied yet
    end

    it "copies round 2 to round 4 for cut players on day 4" do
      match_pick # Ensure match_pick exists

      cut_player_data = {
        "roundId" => { "$numberInt" => "4" }, # Day 4 of tournament
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "firstName" => "Scottie",
            "lastName" => "Scheffler",
            "status" => "cut",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "75" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "76" } }
            ]
          }
        ]
      }

      importer = described_class.new(cut_player_data, tournament)
      importer.process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(4) # All 4 rounds created
      expect(scores.find_by(round: 1).score).to eq(75)
      expect(scores.find_by(round: 2).score).to eq(76)
      expect(scores.find_by(round: 3).score).to eq(75) # Copied from round 1
      expect(scores.find_by(round: 4).score).to eq(76) # Copied from round 2
    end

    it "preserves original golfer's scores when replacement occurs mid-tournament" do
      # Setup: Original golfer (Scottie) completes round 1
      original_golfer = golfer
      create(:score, match_pick: match_pick, round: 1, score: 75, position: "T45", status: "active")

      # Simulate WD replacement: Scottie replaced by Justin Thomas after round 1
      replacement_golfer = create(:golfer, source_id: "33448", f_name: "Justin", l_name: "Thomas")
      match_pick.update!(
        original_golfer_id: original_golfer.id,
        golfer_id: replacement_golfer.id,
        replaced_at_round: 2,
        replacement_reason: "wd"
      )

      # API returns replacement golfer's scores for all rounds
      replacement_data = {
        "leaderboardRows" => [
          {
            "playerId" => "33448", # Justin Thomas
            "firstName" => "Justin",
            "lastName" => "Thomas",
            "status" => "complete",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "73" } }, # Different from original
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "70" } },
              { "roundId" => { "$numberInt" => "3" }, "strokes" => { "$numberInt" => "69" } },
              { "roundId" => { "$numberInt" => "4" }, "strokes" => { "$numberInt" => "68" } }
            ]
          }
        ]
      }

      importer = described_class.new(replacement_data, tournament)
      importer.process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(4)

      # Round 1: Original golfer's score preserved (75, not 73)
      expect(scores.find_by(round: 1).score).to eq(75)

      # Rounds 2-4: Replacement golfer's scores
      expect(scores.find_by(round: 2).score).to eq(70)
      expect(scores.find_by(round: 3).score).to eq(69)
      expect(scores.find_by(round: 4).score).to eq(68)
    end

    it "saves score when roundComplete is true but round not yet in rounds array (API lag)" do
      match_pick

      lag_window_data = {
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "firstName" => "Scottie",
            "lastName" => "Scheffler",
            "status" => "active",
            "roundComplete" => true,
            "currentRound" => { "$numberInt" => "2" },
            "currentRoundScore" => "-4",
            "thru" => "F",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } }
              # Round 2 not yet in rounds array — API lag window
            ]
          }
        ]
      }

      described_class.new(lag_window_data, tournament).process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(2)
      expect(scores.find_by(round: 1).score).to eq(70)
      expect(scores.find_by(round: 2).score).to eq(tournament.par - 4)
    end

    it "continues updating second golfer scores after first golfer finishes their round" do
      scheffler_pick = match_pick

      mcilroy = create(:golfer, source_id: "28237", f_name: "Rory", l_name: "McIlroy")
      mcilroy_pick = create(:match_pick, user: user, tournament: tournament, golfer: mcilroy, drafted: true)

      data = {
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "status" => "complete",
            "roundComplete" => true,
            "currentRound" => { "$numberInt" => "2" },
            "currentRoundScore" => "-3",
            "thru" => "F",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "69" } }
            ]
          },
          {
            "playerId" => "28237",
            "status" => "active",
            "roundComplete" => false,
            "currentRound" => { "$numberInt" => "2" },
            "currentRoundScore" => "-2",
            "thru" => "12",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "71" } }
            ]
          }
        ]
      }

      described_class.new(data, tournament).process

      mcilroy_r2 = Score.find_by(match_pick: mcilroy_pick, round: 2)
      expect(mcilroy_r2).to be_present
      expect(mcilroy_r2.score).to eq(tournament.par - 2)

      # Second import: McIlroy's score improves
      data["leaderboardRows"][1]["currentRoundScore"] = "-4"
      data["leaderboardRows"][1]["thru"] = "16"

      described_class.new(data, tournament).process

      expect(mcilroy_r2.reload.score).to eq(tournament.par - 4)
    end

    it "does not save a bogus score when currentRoundScore is the placeholder dash" do
      match_pick

      no_score_data = {
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "status" => "active",
            "roundComplete" => false,
            "currentRound" => { "$numberInt" => "2" },
            "currentRoundScore" => "-",
            "thru" => "-",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } }
            ]
          }
        ]
      }

      described_class.new(no_score_data, tournament).process

      scores = Score.where(match_pick: match_pick).order(:round)
      expect(scores.count).to eq(1)
      expect(scores.find_by(round: 2)).to be_nil
    end
  end

  describe "#determine_current_round" do
    it "uses top-level roundId from API response" do
      data_with_top_level_round = {
        "roundId" => { "$numberInt" => "3" },
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "status" => "active",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "68" } }
            ]
          }
        ]
      }

      importer = described_class.new(data_with_top_level_round, tournament)
      current_round = importer.send(:determine_current_round)

      # Should use top-level roundId (3), not max from player rounds (2)
      expect(current_round).to eq(3)
    end

    it "falls back to player rounds when top-level roundId missing" do
      data_without_top_level_round = {
        "leaderboardRows" => [
          {
            "playerId" => "46046",
            "status" => "active",
            "rounds" => [
              { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "70" } },
              { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "68" } }
            ]
          }
        ]
      }

      importer = described_class.new(data_without_top_level_round, tournament)
      current_round = importer.send(:determine_current_round)

      # Should fall back to max round from player rounds (2)
      expect(current_round).to eq(2)
    end
  end
end
