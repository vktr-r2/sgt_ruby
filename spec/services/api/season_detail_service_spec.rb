require "rails_helper"

RSpec.describe Api::SeasonDetailService do
  describe ".call" do
    context "with valid year" do
      let!(:users) { create_list(:user, 3) }

      # Create 3 tournaments for 2025 (2 majors, 1 regular)
      let!(:tournament_1) do
        create(:tournament,
          name: "The Masters",
          year: 2025,
          start_date: Date.new(2025, 4, 10),
          end_date: Date.new(2025, 4, 13),
          major_championship: true)
      end

      let!(:tournament_2) do
        create(:tournament,
          name: "Genesis Invitational",
          year: 2025,
          start_date: Date.new(2025, 2, 15),
          end_date: Date.new(2025, 2, 18),
          major_championship: false)
      end

      let!(:tournament_3) do
        create(:tournament,
          name: "PGA Championship",
          year: 2025,
          start_date: Date.new(2025, 5, 15),
          end_date: Date.new(2025, 5, 18),
          major_championship: true)
      end

      before do
        # Tournament 1 (The Masters - major): user1 wins
        create(:match_result, :first_place, user: users[0], tournament: tournament_1, total_score: -6) # -4 + -2 major bonus
        create(:match_result, :second_place, user: users[1], tournament: tournament_1, total_score: -3)
        create(:match_result, :third_place, user: users[2], tournament: tournament_1, total_score: -2)

        # Tournament 2 (Genesis - regular): user2 wins
        create(:match_result, :second_place, user: users[0], tournament: tournament_2, total_score: -3)
        create(:match_result, :first_place, user: users[1], tournament: tournament_2, total_score: -4)
        create(:match_result, :third_place, user: users[2], tournament: tournament_2, total_score: -2)

        # Tournament 3 (PGA - major): user1 wins again
        create(:match_result, :first_place, user: users[0], tournament: tournament_3, total_score: -6) # -4 + -2 major bonus
        create(:match_result, :third_place, user: users[1], tournament: tournament_3, total_score: -2)
        create(:match_result, :second_place, user: users[2], tournament: tournament_3, total_score: -3)
      end

      it "returns season year and tournament count" do
        result = described_class.call(2025)

        expect(result).to have_key(:season_year)
        expect(result).to have_key(:tournament_count)
        expect(result[:season_year]).to eq(2025)
        expect(result[:tournament_count]).to eq(3)
      end

      it "includes full standings with majors_won field" do
        result = described_class.call(2025)

        expect(result).to have_key(:standings)
        expect(result[:standings]).to be_an(Array)
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
          expect(standing).to have_key(:majors_won)
        end
      end

      it "includes all tournaments ordered by start_date" do
        result = described_class.call(2025)

        expect(result).to have_key(:tournaments)
        expect(result[:tournaments]).to be_an(Array)
        expect(result[:tournaments].length).to eq(3)

        # Should be ordered by start_date ascending
        tournament_names = result[:tournaments].map { |t| t[:name] }
        expect(tournament_names).to eq([
          "Genesis Invitational",  # Feb 15
          "The Masters",           # Apr 10
          "PGA Championship"       # May 15
        ])
      end

      it "includes winner information for each tournament" do
        result = described_class.call(2025)

        result[:tournaments].each do |tournament|
          expect(tournament).to have_key(:id)
          expect(tournament).to have_key(:name)
          expect(tournament).to have_key(:start_date)
          expect(tournament).to have_key(:end_date)
          expect(tournament).to have_key(:is_major)
          expect(tournament).to have_key(:winner)

          if tournament[:winner]
            expect(tournament[:winner]).to have_key(:user_id)
            expect(tournament[:winner]).to have_key(:username)
            expect(tournament[:winner]).to have_key(:total_points)
            expect(tournament[:winner]).to have_key(:place)
            expect(tournament[:winner][:place]).to eq(1)
          end
        end
      end

      it "correctly marks major championships" do
        result = described_class.call(2025)

        masters = result[:tournaments].find { |t| t[:name] == "The Masters" }
        genesis = result[:tournaments].find { |t| t[:name] == "Genesis Invitational" }
        pga = result[:tournaments].find { |t| t[:name] == "PGA Championship" }

        expect(masters[:is_major]).to be true
        expect(genesis[:is_major]).to be false
        expect(pga[:is_major]).to be true
      end

      it "calculates majors_won correctly per user" do
        result = described_class.call(2025)

        # user1 won 2 majors (The Masters and PGA Championship)
        # user2 won 1 regular tournament (Genesis)
        # user3 won 0 tournaments

        user1_standing = result[:standings].find { |s| s[:user_id] == users[0].id }
        user2_standing = result[:standings].find { |s| s[:user_id] == users[1].id }
        user3_standing = result[:standings].find { |s| s[:user_id] == users[2].id }

        expect(user1_standing[:majors_won]).to eq(2)
        expect(user2_standing[:majors_won]).to eq(0)
        expect(user3_standing[:majors_won]).to eq(0)
      end
    end

    context "with invalid year" do
      it "raises UnprocessableError when no data for season" do
        expect {
          described_class.call(2030)
        }.to raise_error(Api::SeasonDetailService::UnprocessableError, "No data for season 2030")
      end
    end
  end
end
