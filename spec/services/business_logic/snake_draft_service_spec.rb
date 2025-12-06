require 'rails_helper'

RSpec.describe BusinessLogic::SnakeDraftService, type: :service do
  let(:service) { described_class.new }

  let!(:users) do
    [
      create(:user, name: "User1"),
      create(:user, name: "User2"),
      create(:user, name: "User3"),
      create(:user, name: "User4")
    ]
  end

  let!(:current_tournament) do
    create(:tournament,
           name: "Current Tournament",
           start_date: Date.today + 2.days,
           year: Date.today.year,
           week_number: Date.today.strftime("%V").to_i)
  end

  let!(:golfers) do
    32.times.map { |i| create(:golfer, f_name: "Golfer#{i}", l_name: "Test") }
  end

  before do
    # Create 8 picks for each user for current tournament (all drafted: false)
    users.each_with_index do |user, user_index|
      8.times do |priority|
        golfer = golfers[user_index * 8 + priority]
        create(:match_pick,
               user: user,
               tournament: current_tournament,
               golfer: golfer,
               priority: priority + 1,
               drafted: false)
      end
    end

    allow_any_instance_of(BusinessLogic::TournamentService)
      .to receive(:current_tournament).and_return(current_tournament)
  end

  describe "#execute_draft" do
    context "when there is no previous tournament data" do
      it "randomizes draft order and assigns picks" do
        result = service.execute_draft(current_tournament)

        expect(result[:success]).to be true
        expect(result[:draft_order].length).to eq(4)
        expect(result[:assigned_picks]).to eq(32) # 4 users * 8 picks

        # Verify all picks are now drafted
        drafted_picks = MatchPick.where(tournament: current_tournament, drafted: true)
        expect(drafted_picks.count).to eq(32)
      end
    end

    context "with previous tournament results" do
      let!(:previous_tournament) do
        create(:tournament,
               name: "Previous Tournament",
               start_date: Date.today - 5.days,
               year: Date.today.year,
               week_number: (Date.today - 5.days).strftime("%V").to_i)
      end

      before do
        # Create match results: User4 = 1st, User3 = 2nd, User2 = 3rd, User1 = 4th
        create(:match_result, :first_place, user: users[3], tournament: previous_tournament)
        create(:match_result, :second_place, user: users[2], tournament: previous_tournament)
        create(:match_result, :third_place, user: users[1], tournament: previous_tournament)
        create(:match_result, :fourth_place, user: users[0], tournament: previous_tournament)
      end

      it "uses reverse standings for draft order (4th, 3rd, 2nd, 1st)" do
        result = service.execute_draft(current_tournament)

        expect(result[:success]).to be true
        expect(result[:draft_order]).to eq([users[0], users[1], users[2], users[3]])
      end

      it "executes snake draft pattern correctly" do
        result = service.execute_draft(current_tournament)

        # Round 1 (even index=0): User1, User2, User3, User4
        # Round 2 (odd index=1): User4, User3, User2, User1
        # etc.

        expect(result[:assigned_picks]).to eq(32)

        # Verify all users got 8 picks
        users.each do |user|
          user_picks = MatchPick.where(user: user, tournament: current_tournament, drafted: true)
          expect(user_picks.count).to eq(8)
        end
      end
    end

    context "with tied placements requiring tie-breaking" do
      let!(:previous_tournament) do
        create(:tournament,
               name: "Previous Tournament",
               start_date: Date.today - 5.days,
               year: Date.today.year,
               week_number: (Date.today - 5.days).strftime("%V").to_i)
      end

      let!(:previous_golfers) do
        8.times.map { |i| create(:golfer, f_name: "PrevGolfer#{i}", l_name: "Test") }
      end

      before do
        # Create match results with tie at 2nd place
        create(:match_result, place: 1, total_score: -15, user: users[3], tournament: previous_tournament)
        create(:match_result, place: 2, total_score: -10, user: users[1], tournament: previous_tournament)
        create(:match_result, place: 2, total_score: -10, user: users[2], tournament: previous_tournament)
        create(:match_result, place: 4, total_score: 0, user: users[0], tournament: previous_tournament)

        # Create previous picks for tied users (User2 and User3)
        users[1..2].each_with_index do |user, idx|
          8.times do |i|
            pick = create(:match_pick,
                          user: user,
                          tournament: previous_tournament,
                          golfer: previous_golfers[i],
                          priority: i + 1,
                          drafted: true)

            # User2 has better (lower) scores than User3
            score_value = idx == 0 ? 65 + i : 68 + i
            create(:score, match_pick: pick, score: score_value, round: 1)
          end
        end
      end

      it "applies tie-breaking using lowest scores" do
        result = service.execute_draft(current_tournament)

        # Draft order: User1 (4th), User2 (2nd-better tiebreak), User3 (2nd-worse), User4 (1st)
        expect(result[:draft_order]).to eq([users[0], users[1], users[2], users[3]])
      end
    end

    context "first tournament of year with previous year data" do
      let!(:previous_year_tournament1) do
        create(:tournament,
               name: "Last Year T1",
               start_date: Date.today - 365.days,
               year: Date.today.year - 1,
               week_number: 1)
      end

      let!(:previous_year_tournament2) do
        create(:tournament,
               name: "Last Year T2",
               start_date: Date.today - 360.days,
               year: Date.today.year - 1,
               week_number: 2)
      end

      let!(:first_tournament_of_year) do
        create(:tournament,
               name: "First of Year",
               start_date: Date.new(Date.today.year, 1, 7),
               year: Date.today.year,
               week_number: 1)
      end

      before do
        # User cumulative scores from previous year: User1=-20, User2=-15, User3=-10, User4=-5
        create(:match_result, total_score: -12, user: users[0], tournament: previous_year_tournament1)
        create(:match_result, total_score: -8, user: users[0], tournament: previous_year_tournament2)

        create(:match_result, total_score: -10, user: users[1], tournament: previous_year_tournament1)
        create(:match_result, total_score: -5, user: users[1], tournament: previous_year_tournament2)

        create(:match_result, total_score: -6, user: users[2], tournament: previous_year_tournament1)
        create(:match_result, total_score: -4, user: users[2], tournament: previous_year_tournament2)

        create(:match_result, total_score: -3, user: users[3], tournament: previous_year_tournament1)
        create(:match_result, total_score: -2, user: users[3], tournament: previous_year_tournament2)

        # Create picks for first tournament of year
        users.each_with_index do |user, user_index|
          8.times do |priority|
            golfer = golfers[user_index * 8 + priority]
            create(:match_pick,
                   user: user,
                   tournament: first_tournament_of_year,
                   golfer: golfer,
                   priority: priority + 1,
                   drafted: false)
          end
        end
      end

      it "uses previous year cumulative scores for draft order" do
        result = service.execute_draft(first_tournament_of_year)

        # Worst (highest score) picks first: User4 (-5), User3 (-10), User2 (-15), User1 (-20)
        expect(result[:draft_order]).to eq([users[3], users[2], users[1], users[0]])
      end
    end
  end
end
