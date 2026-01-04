require "rails_helper"

RSpec.describe Api::TournamentScoresService do
  describe ".call" do
    context "with current tournament and scores" do
      let(:tournament) { create(:tournament) }
      let!(:users) { create_list(:user, 3) }
      let!(:golfers) { create_list(:golfer, 12, tournament: tournament) }

      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)

        # Create drafted picks with scores for each user
        users.each_with_index do |u, user_index|
          golfers.sample(4).each_with_index do |golfer, pick_index|
            match_pick = create(:match_pick,
              user: u,
              tournament: tournament,
              golfer: golfer,
              drafted: true,
              priority: pick_index + 1)

            # Create scores - vary by user to ensure proper sorting
            2.times do |round_num|
              create(:score,
                match_pick: match_pick,
                round: round_num + 1,
                score: 70 + (user_index * 2),  # Different totals per user
                position: "T#{user_index + 1}",
                status: "active")
            end
          end
        end
      end

      it "builds leaderboard with user totals" do
        result = described_class.call

        expect(result).to have_key(:tournament)
        expect(result).to have_key(:leaderboard)
        expect(result[:leaderboard].length).to eq(3)

        result[:leaderboard].each do |entry|
          expect(entry).to have_key(:user_id)
          expect(entry).to have_key(:username)
          expect(entry).to have_key(:total_strokes)
          expect(entry).to have_key(:current_position)
          expect(entry).to have_key(:golfers)
        end
      end

      it "sorts users by total strokes ascending" do
        result = described_class.call

        leaderboard = result[:leaderboard]
        totals = leaderboard.map { |entry| entry[:total_strokes] }

        expect(totals).to eq(totals.sort)
        expect(leaderboard.first[:current_position]).to eq(1)
        expect(leaderboard.last[:current_position]).to eq(3)
      end

      it "includes golfer round-by-round scores" do
        result = described_class.call

        first_entry = result[:leaderboard].first
        first_golfer = first_entry[:golfers].first

        expect(first_golfer).to have_key(:golfer_id)
        expect(first_golfer).to have_key(:name)
        expect(first_golfer).to have_key(:total_score)
        expect(first_golfer).to have_key(:position)
        expect(first_golfer).to have_key(:status)
        expect(first_golfer).to have_key(:rounds)
        expect(first_golfer).to have_key(:was_replaced)

        expect(first_golfer[:rounds].length).to eq(2)
        first_golfer[:rounds].each do |round|
          expect(round).to have_key(:round)
          expect(round).to have_key(:score)
          expect(round).to have_key(:position)
        end
      end

      it "marks replaced golfers correctly" do
        replaced_golfer = golfers.last
        original_golfer = golfers.first

        match_pick = create(:match_pick,
          user: users.first,
          tournament: tournament,
          golfer: replaced_golfer,
          original_golfer_id: original_golfer.id,
          drafted: true,
          priority: 5)

        create(:score,
          match_pick: match_pick,
          round: 1,
          score: 72,
          position: "T10",
          status: "active")

        result = described_class.call

        user_entry = result[:leaderboard].find { |e| e[:user_id] == users.first.id }
        replaced_golfer_data = user_entry[:golfers].find { |g| g[:golfer_id] == replaced_golfer.id }

        expect(replaced_golfer_data[:was_replaced]).to be true
      end

      it "handles cut golfers" do
        cut_match_pick = users.first.match_picks.where(drafted: true).first
        cut_match_pick.scores.update_all(status: "cut")

        result = described_class.call

        user_entry = result[:leaderboard].find { |e| e[:user_id] == users.first.id }
        cut_golfer = user_entry[:golfers].find { |g| g[:golfer_id] == cut_match_pick.golfer_id }

        expect(cut_golfer[:status]).to eq("cut")
      end

      it "handles withdrawn golfers" do
        wd_match_pick = users.first.match_picks.where(drafted: true).first
        wd_match_pick.scores.update_all(status: "wd")

        result = described_class.call

        user_entry = result[:leaderboard].find { |e| e[:user_id] == users.first.id }
        wd_golfer = user_entry[:golfers].find { |g| g[:golfer_id] == wd_match_pick.golfer_id }

        expect(wd_golfer[:status]).to eq("wd")
      end
    end

    context "without current tournament" do
      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(nil)
      end

      it "returns nil tournament and empty leaderboard" do
        result = described_class.call

        expect(result[:tournament]).to be_nil
        expect(result[:leaderboard]).to eq([])
      end
    end
  end
end
