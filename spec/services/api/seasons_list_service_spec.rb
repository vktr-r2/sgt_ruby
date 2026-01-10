require "rails_helper"

RSpec.describe Api::SeasonsListService do
  describe ".call" do
    context "with multiple completed seasons" do
      let!(:users) { create_list(:user, 4) }

      # Create 2025 season (2 tournaments)
      let!(:tournament_2025_1) do
        create(:tournament,
          name: "The Masters 2025",
          year: 2025,
          start_date: Date.new(2025, 1, 10),
          end_date: Date.new(2025, 1, 13),
          major_championship: true)
      end

      let!(:tournament_2025_2) do
        create(:tournament,
          name: "PGA Championship 2025",
          year: 2025,
          start_date: Date.new(2025, 1, 17),
          end_date: Date.new(2025, 1, 20),
          major_championship: true)
      end

      # Create 2024 season (1 tournament)
      let!(:tournament_2024_1) do
        create(:tournament,
          name: "Genesis Invitational 2024",
          year: 2024,
          start_date: Date.new(2024, 1, 10),
          end_date: Date.new(2024, 1, 13),
          major_championship: false)
      end

      before do
        # 2025 Season Results
        # Tournament 1: user1 wins (-4), user2 second (-3), user3 third (-2), user4 fourth (-1)
        create(:match_result, :first_place, user: users[0], tournament: tournament_2025_1, total_score: -4, winner_picked: true, cuts_missed: 0)
        create(:match_result, :second_place, user: users[1], tournament: tournament_2025_1, total_score: -3, winner_picked: false, cuts_missed: 1)
        create(:match_result, :third_place, user: users[2], tournament: tournament_2025_1, total_score: -2, winner_picked: true, cuts_missed: 0)
        create(:match_result, :fourth_place, user: users[3], tournament: tournament_2025_1, total_score: -1, winner_picked: false, cuts_missed: 2)

        # Tournament 2: user2 wins (-4), user1 second (-3), user3 third (-2), user4 fourth (-1)
        create(:match_result, place: 2, user: users[0], tournament: tournament_2025_2, total_score: -3, winner_picked: false, cuts_missed: 1)
        create(:match_result, place: 1, user: users[1], tournament: tournament_2025_2, total_score: -6, winner_picked: true, cuts_missed: 0) # -4 + -2 major bonus
        create(:match_result, :third_place, user: users[2], tournament: tournament_2025_2, total_score: -2, winner_picked: false, cuts_missed: 1)
        create(:match_result, :fourth_place, user: users[3], tournament: tournament_2025_2, total_score: -1, winner_picked: true, cuts_missed: 0)

        # 2024 Season Results
        # user3 wins, user1 second, user2 third, user4 fourth
        create(:match_result, :first_place, user: users[2], tournament: tournament_2024_1, total_score: -4, winner_picked: false, cuts_missed: 0)
        create(:match_result, :second_place, user: users[0], tournament: tournament_2024_1, total_score: -3, winner_picked: true, cuts_missed: 1)
        create(:match_result, :third_place, user: users[1], tournament: tournament_2024_1, total_score: -2, winner_picked: false, cuts_missed: 0)
        create(:match_result, :fourth_place, user: users[3], tournament: tournament_2024_1, total_score: -1, winner_picked: true, cuts_missed: 2)
      end

      it "returns seasons in descending year order" do
        result = described_class.call

        expect(result).to have_key(:seasons)
        expect(result[:seasons].length).to eq(2)

        years = result[:seasons].map { |s| s[:year] }
        expect(years).to eq([2025, 2024])
      end

      it "includes correct tournament count per season" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }
        season_2024 = result[:seasons].find { |s| s[:year] == 2024 }

        expect(season_2025[:tournament_count]).to eq(2)
        expect(season_2024[:tournament_count]).to eq(1)
      end

      it "identifies correct season winner" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }

        # user1: -4 + -3 = -7 total points (winner)
        # user2: -3 + -6 = -9 total points (actually the winner!)
        expect(season_2025[:season_winner]).to be_a(Hash)
        expect(season_2025[:season_winner][:user_id]).to eq(users[1].id)
        expect(season_2025[:season_winner][:username]).to eq(users[1].name)
        expect(season_2025[:season_winner][:total_points]).to eq(-9)
      end

      it "includes full standings preview with 4 users" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }

        expect(season_2025[:standings_preview]).to be_an(Array)
        expect(season_2025[:standings_preview].length).to eq(4)

        # Check structure of each standing
        season_2025[:standings_preview].each do |standing|
          expect(standing).to have_key(:rank)
          expect(standing).to have_key(:username)
          expect(standing).to have_key(:total_points)
        end

        # Check rankings are correct (sorted by total_points ascending)
        ranks = season_2025[:standings_preview].map { |s| s[:rank] }
        expect(ranks).to eq([1, 2, 3, 4])
      end

      it "calculates majors won correctly" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }

        # user1 won tournament_2025_1 (major)
        # user2 won tournament_2025_2 (major)
        # Should identify the user with most major wins (tied at 1 each, so first by points)
        expect(season_2025[:majors_won]).to be_a(Hash)
        expect(season_2025[:majors_won]).to have_key(:user_id)
        expect(season_2025[:majors_won]).to have_key(:username)
        expect(season_2025[:majors_won]).to have_key(:count)

        # Either user1 or user2 should be the leader (both have 1 major win)
        expect([users[0].id, users[1].id]).to include(season_2025[:majors_won][:user_id])
        expect(season_2025[:majors_won][:count]).to eq(1)
      end

      it "aggregates total winners picked" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }
        season_2024 = result[:seasons].find { |s| s[:year] == 2024 }

        # 2025: tournament 1 (user1, user3 picked winner), tournament 2 (user2, user4 picked winner) = 4 total
        expect(season_2025[:total_winners_picked]).to eq(4)

        # 2024: tournament 1 (user1, user4 picked winner) = 2 total
        expect(season_2024[:total_winners_picked]).to eq(2)
      end

      it "aggregates total cuts missed" do
        result = described_class.call

        season_2025 = result[:seasons].find { |s| s[:year] == 2025 }

        # 2025 Tournament 1: 0 + 1 + 0 + 2 = 3 cuts
        # 2025 Tournament 2: 1 + 0 + 1 + 0 = 2 cuts
        # Total: 5 cuts
        expect(season_2025[:total_cuts_missed]).to eq(5)
      end
    end

    context "without completed seasons" do
      it "returns empty array when no completed seasons exist" do
        result = described_class.call

        expect(result).to have_key(:seasons)
        expect(result[:seasons]).to be_an(Array)
        expect(result[:seasons]).to be_empty
      end
    end
  end
end
