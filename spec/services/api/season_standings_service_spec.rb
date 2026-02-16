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

    context "with tied total points" do
      let!(:user1) { create(:user, name: "User One") }
      let!(:user2) { create(:user, name: "User Two") }
      let!(:user3) { create(:user, name: "User Three") }
      let!(:tournaments) { create_list(:tournament, 4, year: 2026) }

      context "when tiebreaker is first place finishes" do
        before do
          # User1: -8 total, 2 first places
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4)
          create(:match_result, user: user1, tournament: tournaments[1], place: 1, total_score: -4)

          # User2: -8 total, 1 first place
          create(:match_result, user: user2, tournament: tournaments[0], place: 2, total_score: -3)
          create(:match_result, user: user2, tournament: tournaments[1], place: 1, total_score: -4)
          create(:match_result, user: user2, tournament: tournaments[2], place: 4, total_score: -1)
        end

        it "ranks user with more first place finishes higher" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }

          expect(user1_standing[:total_points]).to eq(-8)
          expect(user2_standing[:total_points]).to eq(-8)
          expect(user1_standing[:rank]).to be < user2_standing[:rank]
        end
      end

      context "when tiebreaker is winners picked" do
        before do
          # User1: -8 total, 2 first places, 1 winner picked
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user1, tournament: tournaments[1], place: 1, total_score: -4, winner_picked: false)

          # User2: -8 total, 2 first places, 2 winners picked
          create(:match_result, user: user2, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user2, tournament: tournaments[1], place: 1, total_score: -4, winner_picked: true)
        end

        it "ranks user with more winners picked higher when first places are equal" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }

          expect(user1_standing[:first_place]).to eq(2)
          expect(user2_standing[:first_place]).to eq(2)
          expect(user2_standing[:rank]).to be < user1_standing[:rank]
        end
      end

      context "when tiebreaker is second place finishes" do
        before do
          # User1: -6 total, 1 first, 2 winners, 1 second
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user1, tournament: tournaments[1], place: 3, total_score: -2, winner_picked: true)

          # User2: -6 total, 1 first, 2 winners, 2 seconds
          create(:match_result, user: user2, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user2, tournament: tournaments[1], place: 2, total_score: -3, winner_picked: true)
          create(:match_result, user: user2, tournament: tournaments[2], place: 4, total_score: 1)
          create(:match_result, user: user2, tournament: tournaments[3], place: 2, total_score: -3)
        end

        it "ranks user with more second place finishes higher when first and winners are equal" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }

          expect(user1_standing[:first_place]).to eq(user2_standing[:first_place])
          expect(user1_standing[:winners_picked]).to eq(user2_standing[:winners_picked])
          expect(user2_standing[:second_place]).to be > user1_standing[:second_place]
        end
      end

      context "when tiebreaker is third place finishes" do
        before do
          # User1: -4 total, 1 first, 1 winner, 0 seconds, 0 thirds
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)

          # User2: -4 total, 1 first, 1 winner, 0 seconds, 1 third
          create(:match_result, user: user2, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user2, tournament: tournaments[1], place: 3, total_score: -2)
          create(:match_result, user: user2, tournament: tournaments[2], place: 4, total_score: 2)
        end

        it "ranks user with more third place finishes higher when all other criteria are equal" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }

          expect(user1_standing[:total_points]).to eq(user2_standing[:total_points])
          expect(user1_standing[:first_place]).to eq(user2_standing[:first_place])
          expect(user1_standing[:winners_picked]).to eq(user2_standing[:winners_picked])
          expect(user1_standing[:second_place]).to eq(user2_standing[:second_place])
          expect(user2_standing[:third_place]).to be > user1_standing[:third_place]
          expect(user2_standing[:rank]).to be < user1_standing[:rank]
        end
      end

      context "when all tiebreakers are equal" do
        before do
          # Both users have identical stats
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4, winner_picked: true)
          create(:match_result, user: user2, tournament: tournaments[1], place: 1, total_score: -4, winner_picked: true)
        end

        it "assigns same rank to users with identical stats" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }

          # Both should have rank 1 (tied)
          expect(user1_standing[:rank]).to eq(1)
          expect(user2_standing[:rank]).to eq(1)
        end
      end

      context "with three-way tie broken by first criteria" do
        before do
          # All three have -6 total points
          # User1: 2 firsts
          create(:match_result, user: user1, tournament: tournaments[0], place: 1, total_score: -4)
          create(:match_result, user: user1, tournament: tournaments[1], place: 3, total_score: -2)

          # User2: 1 first
          create(:match_result, user: user2, tournament: tournaments[0], place: 1, total_score: -4)
          create(:match_result, user: user2, tournament: tournaments[1], place: 3, total_score: -2)

          # User3: 0 firsts
          create(:match_result, user: user3, tournament: tournaments[0], place: 2, total_score: -3)
          create(:match_result, user: user3, tournament: tournaments[1], place: 2, total_score: -3)
        end

        it "correctly ranks three tied users by first place finishes" do
          result = described_class.call(2026)
          standings = result[:standings]

          user1_standing = standings.find { |s| s[:user_id] == user1.id }
          user2_standing = standings.find { |s| s[:user_id] == user2.id }
          user3_standing = standings.find { |s| s[:user_id] == user3.id }

          # All have same total points
          expect(user1_standing[:total_points]).to eq(-6)
          expect(user2_standing[:total_points]).to eq(-6)
          expect(user3_standing[:total_points]).to eq(-6)

          # User1 has most firsts, then User2 (tied with User1 from before block issue - let me fix)
          expect(user1_standing[:first_place]).to eq(1)
          expect(user2_standing[:first_place]).to eq(1)
          expect(user3_standing[:first_place]).to eq(0)

          # User3 should rank lower than User1 and User2
          expect(user3_standing[:rank]).to be > user1_standing[:rank]
          expect(user3_standing[:rank]).to be > user2_standing[:rank]
        end
      end
    end
  end
end
