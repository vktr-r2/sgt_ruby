require "rails_helper"

RSpec.describe Api::SeasonStandingsService do
  describe ".call" do
    context "with completed tournaments" do
      let!(:users) { create_list(:user, 3) }
      let!(:tournaments) { create_list(:tournament, 3, year: 2026) }

      before do
        users.each_with_index do |u, user_index|
          tournaments.each_with_index do |tournament, tourn_index|
            create(:match_result,
              user: u,
              tournament: tournament,
              place: ((user_index + tourn_index) % 4) + 1,
              total_score: -((user_index + tourn_index) % 4) - 1,
              winner_picked: (user_index + tourn_index).even?,
              cuts_missed: user_index)
          end
        end
      end

      it "returns season year and standings" do
        result = described_class.call

        expect(result).to have_key(:season_year)
        expect(result).to have_key(:last_updated)
        expect(result).to have_key(:standings)
        expect(result[:season_year]).to eq(Date.current.year)
      end

      it "builds standings with user statistics" do
        result = described_class.call

        expect(result[:standings].length).to eq(3)

        result[:standings].each do |standing|
          expect(standing).to have_key(:rank)
          expect(standing).to have_key(:user_id)
          expect(standing).to have_key(:username)
          expect(standing).to have_key(:total_points)
          expect(standing).to have_key(:tournaments_played)
          expect(standing).to have_key(:wins)
          expect(standing).to have_key(:top_3_finishes)
          expect(standing).to have_key(:winners_picked)
          expect(standing).to have_key(:total_cuts_missed)
        end
      end

      it "sorts standings by total points ascending" do
        result = described_class.call

        standings = result[:standings]
        total_points = standings.map { |s| s[:total_points] }

        expect(total_points).to eq(total_points.sort)
        expect(standings.first[:rank]).to eq(1)
        expect(standings.last[:rank]).to eq(3)
      end

      it "calculates cumulative statistics correctly" do
        result = described_class.call

        first_standing = result[:standings].first

        expect(first_standing[:tournaments_played]).to be > 0
        expect(first_standing[:total_points]).to be <= 0  # Points are negative
      end

      it "filters by year parameter" do
        # Create older tournament
        old_tournament = create(:tournament, year: 2025, start_date: Date.new(2025, 1, 15))
        create(:match_result,
          user: users.first,
          tournament: old_tournament,
          place: 1,
          total_score: -4)

        result = described_class.call(2026)

        expect(result[:season_year]).to eq(2026)

        # Check that old tournament results aren't included
        first_standing = result[:standings].find { |s| s[:user_id] == users.first.id }
        expect(first_standing[:tournaments_played]).to eq(3)  # Only 2026 tournaments
      end
    end

    context "without tournaments" do
      let!(:users) { create_list(:user, 2) }

      it "returns empty standings when no match results exist" do
        result = described_class.call

        expect(result[:standings]).to be_an(Array)
        expect(result[:standings].length).to eq(0)
      end
    end
  end
end
