require "rails_helper"

RSpec.describe Api::TournamentResultsService do
  describe ".call" do
    context "with completed tournament" do
      let(:tournament) { create(:tournament, end_date: 1.week.ago) }
      let!(:users) { create_list(:user, 3) }
      let!(:golfers) { create_list(:golfer, 12, tournament: tournament) }

      before do
        users.each_with_index do |u, index|
          create(:match_result,
            user: u,
            tournament: tournament,
            place: index + 1,
            total_score: -(4 - index),
            winner_picked: index.zero?,
            cuts_missed: index)

          golfers.sample(4).each do |golfer|
            match_pick = create(:match_pick,
              user: u,
              tournament: tournament,
              golfer: golfer,
              drafted: true)

            4.times do |round_num|
              create(:score,
                match_pick: match_pick,
                round: round_num + 1,
                score: 70,
                status: "complete")
            end
          end
        end
      end

      it "returns tournament and results data" do
        result = described_class.call(tournament.id)

        expect(result).to have_key(:tournament)
        expect(result).to have_key(:results)
      end

      it "builds results ordered by place" do
        result = described_class.call(tournament.id)

        results = result[:results]
        expect(results.length).to eq(3)
        expect(results.first[:place]).to eq(1)
        expect(results.last[:place]).to eq(3)
      end

      it "includes user statistics" do
        result = described_class.call(tournament.id)

        first_result = result[:results].first
        expect(first_result).to have_key(:user_id)
        expect(first_result).to have_key(:username)
        expect(first_result).to have_key(:total_points)
        expect(first_result).to have_key(:total_strokes)
        expect(first_result).to have_key(:winner_picked)
        expect(first_result).to have_key(:cuts_missed)
        expect(first_result).to have_key(:golfers)
      end

      it "includes golfer details with final scores" do
        result = described_class.call(tournament.id)

        first_result = result[:results].first
        first_golfer = first_result[:golfers].first

        expect(first_golfer).to have_key(:golfer_id)
        expect(first_golfer).to have_key(:name)
        expect(first_golfer).to have_key(:total_score)
        expect(first_golfer).to have_key(:final_position)
        expect(first_golfer).to have_key(:status)
        expect(first_golfer).to have_key(:was_replaced)
      end
    end

    context "with in-progress tournament" do
      let(:tournament) { create(:tournament, end_date: 1.week.from_now) }

      it "raises UnprocessableError" do
        expect do
          described_class.call(tournament.id)
        end.to raise_error(Api::TournamentResultsService::UnprocessableError)
      end
    end

    context "with non-existent tournament" do
      it "raises ActiveRecord::RecordNotFound" do
        expect do
          described_class.call(999999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
