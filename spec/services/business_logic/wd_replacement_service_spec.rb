require "rails_helper"

RSpec.describe BusinessLogic::WdReplacementService do
  let(:tournament) { create(:tournament, tournament_id: "475", name: "Valspar Championship") }
  let(:user) { create(:user) }

  # WD golfer - Viktor Hovland
  let(:wd_golfer) { create(:golfer, source_id: "46717", f_name: "Viktor", l_name: "Hovland") }

  # Replacement candidate - Justin Thomas (worse position)
  let(:replacement_golfer) { create(:golfer, source_id: "33448", f_name: "Justin", l_name: "Thomas") }

  # User's drafted pick that will be replaced
  let(:match_pick) { create(:match_pick, user: user, tournament: tournament, golfer: wd_golfer, drafted: true) }

  # Leaderboard data with WD golfer
  let(:leaderboard_data) do
    {
      "leaderboardRows" => [
        {
          "playerId" => "46717",
          "firstName" => "Viktor",
          "lastName" => "Hovland",
          "status" => "wd",
          "position" => "WD",
          "rounds" => []
        },
        {
          "playerId" => "33448",
          "firstName" => "Justin",
          "lastName" => "Thomas",
          "status" => "complete",
          "position" => "15",
          "rounds" => [
            { "roundId" => { "$numberInt" => "1" }, "strokes" => { "$numberInt" => "73" } },
            { "roundId" => { "$numberInt" => "2" }, "strokes" => { "$numberInt" => "70" } }
          ]
        }
      ]
    }
  end

  describe "#detect_and_replace_wd_golfers" do
    context "when golfer withdraws mid-tournament" do
      it "replaces with golfer at same or worse position" do
        # Setup: Create a score record showing WD golfer was in 10th place previously
        create(:score, :with_position, match_pick: match_pick, round: 1, position: "10", status: "active", score: 70)

        # Ensure replacement golfer exists
        replacement_golfer

        service = described_class.new(tournament, 2)
        service.detect_and_replace_wd_golfers(leaderboard_data)

        # Reload match_pick to get updated data
        match_pick.reload

        # Should update golfer_id to replacement
        expect(match_pick.golfer_id).to eq(replacement_golfer.id)

        # Should preserve original golfer ID
        expect(match_pick.original_golfer_id).to eq(wd_golfer.id)

        # Should track replacement round
        expect(match_pick.replaced_at_round).to eq(2)

        # Should set replacement reason
        expect(match_pick.replacement_reason).to eq("wd")
      end
    end

    context "when golfer withdraws early (before first API call)" do
      it "uses randomizer with all undrafted golfers" do
        # No prior scores - early WD scenario
        # Ensure both golfers exist and replacement is available
        match_pick # Creates wd_golfer via association
        replacement_golfer # Ensures it exists

        service = described_class.new(tournament, 1)
        service.detect_and_replace_wd_golfers(leaderboard_data)

        match_pick.reload

        # Should have been replaced (golfer changed)
        expect(match_pick.golfer_id).to eq(replacement_golfer.id)
        expect(match_pick.original_golfer_id).to eq(wd_golfer.id)
        expect(match_pick.replaced_at_round).to eq(1)
        expect(match_pick.replacement_reason).to eq("wd_early")
      end
    end

    context "when golfer already replaced" do
      it "skips duplicate replacement" do
        # Setup: match_pick already has a replacement
        original_replacement = create(:golfer, source_id: "99999")
        match_pick.update!(original_golfer_id: wd_golfer.id, golfer_id: original_replacement.id, replacement_reason: "wd")

        replacement_golfer # Ensure second potential replacement exists

        service = described_class.new(tournament, 2)
        service.detect_and_replace_wd_golfers(leaderboard_data)

        match_pick.reload

        # Should NOT change to second replacement
        expect(match_pick.golfer_id).to eq(original_replacement.id)
        expect(match_pick.original_golfer_id).to eq(wd_golfer.id)
      end
    end
  end

  describe "#parse_position_for_comparison" do
    let(:service) { described_class.new(tournament, 1) }

    it "parses tied positions correctly" do
      expect(service.send(:parse_position_for_comparison, "T5")).to eq(5)
      expect(service.send(:parse_position_for_comparison, "T20")).to eq(20)
    end

    it "parses numeric positions correctly" do
      expect(service.send(:parse_position_for_comparison, "1")).to eq(1)
      expect(service.send(:parse_position_for_comparison, "15")).to eq(15)
    end

    it "treats CUT as worst position" do
      expect(service.send(:parse_position_for_comparison, "CUT")).to eq(Float::INFINITY)
    end

    it "treats WD as worst position" do
      expect(service.send(:parse_position_for_comparison, "WD")).to eq(Float::INFINITY)
    end

    it "treats nil as worst position" do
      expect(service.send(:parse_position_for_comparison, nil)).to eq(Float::INFINITY)
    end
  end
end
