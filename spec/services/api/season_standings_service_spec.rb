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
          expect(standing).to have_key(:first_place)
          expect(standing).to have_key(:second_place)
          expect(standing).to have_key(:third_place)
          expect(standing).to have_key(:fourth_place)
          expect(standing).to have_key(:majors_won)
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

      it "calculates placement counts correctly" do
        result = described_class.call

        # Each user should have placement data from the 3 tournaments
        result[:standings].each do |standing|
          total_placements = standing[:first_place] + standing[:second_place] +
                            standing[:third_place] + standing[:fourth_place]
          expect(total_placements).to eq(3) # 3 tournaments
        end
      end

      it "calculates majors_won correctly" do
        # Create a major tournament with a winner
        major = create(:tournament, year: 2026, major_championship: true)
        create(:match_result, user: users.first, tournament: major, place: 1, total_score: -6)

        result = described_class.call

        first_user_standing = result[:standings].find { |s| s[:user_id] == users.first.id }
        expect(first_user_standing[:majors_won]).to eq(1)

        # Other users should have 0 majors won
        other_standings = result[:standings].reject { |s| s[:user_id] == users.first.id }
        other_standings.each do |standing|
          expect(standing[:majors_won]).to eq(0)
        end
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

        # Check that old tournament results aren't included by verifying placement counts
        first_standing = result[:standings].find { |s| s[:user_id] == users.first.id }
        total_placements = first_standing[:first_place] + first_standing[:second_place] +
                          first_standing[:third_place] + first_standing[:fourth_place]
        expect(total_placements).to eq(3) # Only 2026 tournaments
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
