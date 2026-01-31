require "rails_helper"

RSpec.describe LeaderboardSnapshot, type: :model do
  describe "associations" do
    it { should belong_to(:tournament) }
  end

  describe "validations" do
    it { should validate_presence_of(:tournament_id) }
    it { should validate_presence_of(:leaderboard_data) }
    it { should validate_presence_of(:fetched_at) }
  end

  describe ".save_snapshot" do
    let!(:tournament) { create(:tournament) }
    let(:leaderboard_data) do
      [
        { "player_id" => "123", "name" => "Tiger Woods", "position" => "1" },
        { "player_id" => "456", "name" => "Rory McIlroy", "position" => "2" }
      ]
    end

    context "when no snapshot exists" do
      it "creates a new snapshot" do
        expect {
          LeaderboardSnapshot.save_snapshot(
            tournament: tournament,
            leaderboard_data: leaderboard_data,
            current_round: 2,
            cut_line_score: "-3",
            cut_line_count: 73
          )
        }.to change(LeaderboardSnapshot, :count).by(1)
      end

      it "saves the leaderboard data" do
        snapshot = LeaderboardSnapshot.save_snapshot(
          tournament: tournament,
          leaderboard_data: leaderboard_data,
          current_round: 2,
          cut_line_score: "-3",
          cut_line_count: 73
        )

        expect(snapshot.leaderboard_data).to eq(leaderboard_data)
        expect(snapshot.current_round).to eq(2)
        expect(snapshot.cut_line_score).to eq("-3")
        expect(snapshot.cut_line_count).to eq(73)
      end

      it "sets fetched_at timestamp" do
        snapshot = LeaderboardSnapshot.save_snapshot(
          tournament: tournament,
          leaderboard_data: leaderboard_data,
          current_round: 2,
          cut_line_score: nil,
          cut_line_count: nil
        )

        expect(snapshot.fetched_at).to be_within(1.second).of(Time.current)
      end
    end

    context "when snapshot already exists for tournament" do
      let!(:existing_snapshot) do
        create(:leaderboard_snapshot,
          tournament: tournament,
          leaderboard_data: [{ "player_id" => "old" }],
          current_round: 1
        )
      end

      it "updates existing snapshot instead of creating new" do
        expect {
          LeaderboardSnapshot.save_snapshot(
            tournament: tournament,
            leaderboard_data: leaderboard_data,
            current_round: 2,
            cut_line_score: "-3",
            cut_line_count: 73
          )
        }.not_to change(LeaderboardSnapshot, :count)
      end

      it "updates the data" do
        LeaderboardSnapshot.save_snapshot(
          tournament: tournament,
          leaderboard_data: leaderboard_data,
          current_round: 2,
          cut_line_score: "-3",
          cut_line_count: 73
        )

        existing_snapshot.reload
        expect(existing_snapshot.leaderboard_data).to eq(leaderboard_data)
        expect(existing_snapshot.current_round).to eq(2)
      end
    end

    context "when snapshots exist for other tournaments" do
      let!(:other_tournament) { create(:tournament) }
      let!(:other_snapshot) do
        create(:leaderboard_snapshot,
          tournament: other_tournament,
          leaderboard_data: [{ "player_id" => "other" }]
        )
      end

      it "deletes snapshots for other tournaments" do
        LeaderboardSnapshot.save_snapshot(
          tournament: tournament,
          leaderboard_data: leaderboard_data,
          current_round: 2,
          cut_line_score: nil,
          cut_line_count: nil
        )

        expect(LeaderboardSnapshot.find_by(id: other_snapshot.id)).to be_nil
      end

      it "keeps only current tournament snapshot" do
        LeaderboardSnapshot.save_snapshot(
          tournament: tournament,
          leaderboard_data: leaderboard_data,
          current_round: 2,
          cut_line_score: nil,
          cut_line_count: nil
        )

        expect(LeaderboardSnapshot.count).to eq(1)
        expect(LeaderboardSnapshot.first.tournament_id).to eq(tournament.id)
      end
    end
  end
end
