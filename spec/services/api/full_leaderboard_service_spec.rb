require "rails_helper"

RSpec.describe Api::FullLeaderboardService do
  describe ".call" do
    let(:tournament_service) { instance_double(BusinessLogic::TournamentService) }

    before do
      allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
    end

    context "when no current tournament" do
      before do
        allow(tournament_service).to receive(:current_tournament).and_return(nil)
      end

      it "returns null response" do
        result = described_class.call

        expect(result[:tournament]).to be_nil
        expect(result[:players]).to eq([])
        expect(result[:fetched_at]).to be_nil
      end
    end

    context "when current tournament exists" do
      let!(:tournament) { create(:tournament, par: 72) }
      let!(:golfer1) { create(:golfer, source_id: "123") }
      let!(:golfer2) { create(:golfer, source_id: "456") }
      let!(:match_pick) { create(:match_pick, tournament: tournament, golfer: golfer1, drafted: true) }

      let(:leaderboard_data) do
        [
          { "player_id" => "123", "name" => "Tiger Woods", "position" => "1", "status" => "active",
            "total_strokes" => 140, "total_to_par" => -4, "rounds" => [ { "round" => 1, "score" => 70 } ] },
          { "player_id" => "456", "name" => "Rory McIlroy", "position" => "T2", "status" => "active",
            "total_strokes" => 142, "total_to_par" => -2, "rounds" => [ { "round" => 1, "score" => 72 } ] }
        ]
      end

      let!(:snapshot) do
        create(:leaderboard_snapshot,
               tournament: tournament,
               leaderboard_data: leaderboard_data,
               current_round: 2,
               cut_line_score: "-3",
               cut_line_count: 73,
               fetched_at: Time.zone.parse("2026-01-31 12:00:00")
        )
      end

      before do
        allow(tournament_service).to receive(:current_tournament).and_return(tournament)
      end

      it "returns tournament data" do
        result = described_class.call

        expect(result[:tournament][:id]).to eq(tournament.id)
        expect(result[:tournament][:name]).to eq(tournament.name)
        expect(result[:tournament][:par]).to eq(72)
      end

      it "returns current round" do
        result = described_class.call

        expect(result[:current_round]).to eq(2)
      end

      it "returns cut line info" do
        result = described_class.call

        expect(result[:cut_line][:score]).to eq("-3")
        expect(result[:cut_line][:count]).to eq(73)
      end

      it "returns fetched_at timestamp" do
        result = described_class.call

        expect(result[:fetched_at]).to be_present
        expect(result[:fetched_at]).to include("2026-01-31")
      end

      it "returns all players sorted by position" do
        result = described_class.call

        expect(result[:players].length).to eq(2)
        expect(result[:players][0][:name]).to eq("Tiger Woods")
        expect(result[:players][1][:name]).to eq("Rory McIlroy")
      end

      it "includes drafter name for drafted players" do
        result = described_class.call

        tiger = result[:players].find { |p| p[:player_id] == "123" }
        rory = result[:players].find { |p| p[:player_id] == "456" }

        expect(tiger[:drafted_by]).to be_present
        expect(rory[:drafted_by]).to be_nil
      end

      it "includes player details" do
        result = described_class.call

        player = result[:players][0]
        expect(player[:position]).to eq("1")
        expect(player[:status]).to eq("active")
        expect(player[:total_strokes]).to eq(140)
        expect(player[:total_to_par]).to eq(-4)
      end
    end

    context "when no snapshot exists for tournament" do
      let!(:tournament) { create(:tournament) }

      before do
        allow(tournament_service).to receive(:current_tournament).and_return(tournament)
      end

      it "returns null response" do
        result = described_class.call

        expect(result[:tournament]).to be_nil
        expect(result[:players]).to eq([])
      end
    end

    context "position sorting" do
      let!(:tournament) { create(:tournament) }
      let(:leaderboard_data) do
        [
          { "player_id" => "1", "name" => "Cut Player", "position" => "CUT", "status" => "cut" },
          { "player_id" => "2", "name" => "Third", "position" => "3", "status" => "active" },
          { "player_id" => "3", "name" => "Tied Fifth", "position" => "T5", "status" => "active" },
          { "player_id" => "4", "name" => "First", "position" => "1", "status" => "active" },
          { "player_id" => "5", "name" => "WD Player", "position" => "WD", "status" => "wd" }
        ]
      end

      let!(:snapshot) do
        create(:leaderboard_snapshot,
               tournament: tournament,
               leaderboard_data: leaderboard_data,
               current_round: 2
        )
      end

      before do
        allow(tournament_service).to receive(:current_tournament).and_return(tournament)
      end

      it "sorts players by position correctly" do
        result = described_class.call

        positions = result[:players].map { |p| p[:position] }
        expect(positions).to eq([ "1", "3", "T5", "CUT", "WD" ])
      end
    end
  end
end
