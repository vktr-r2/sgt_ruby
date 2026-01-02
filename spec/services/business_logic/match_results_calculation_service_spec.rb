require "rails_helper"

RSpec.describe BusinessLogic::MatchResultsCalculationService do
  let(:tournament) { create(:tournament, tournament_id: "475", name: "Valspar Championship", major_championship: false) }
  let(:users) { create_list(:user, 4) }

  # Create golfers for testing
  let(:golfer1) { create(:golfer, source_id: "1001", f_name: "Scottie", l_name: "Scheffler") }
  let(:golfer2) { create(:golfer, source_id: "1002", f_name: "Rory", l_name: "McIlroy") }
  let(:golfer3) { create(:golfer, source_id: "1003", f_name: "Jon", l_name: "Rahm") }
  let(:golfer4) { create(:golfer, source_id: "1004", f_name: "Viktor", l_name: "Hovland") }
  let(:golfer5) { create(:golfer, source_id: "1005", f_name: "Justin", l_name: "Thomas") }
  let(:golfer6) { create(:golfer, source_id: "1006", f_name: "Patrick", l_name: "Cantlay") }
  let(:golfer7) { create(:golfer, source_id: "1007", f_name: "Xander", l_name: "Schauffele") }
  let(:golfer8) { create(:golfer, source_id: "1008", f_name: "Collin", l_name: "Morikawa") }
  let(:golfer9) { create(:golfer, source_id: "1009", f_name: "Max", l_name: "Homa") }
  let(:golfer10) { create(:golfer, source_id: "1010", f_name: "Tony", l_name: "Finau") }
  let(:golfer11) { create(:golfer, source_id: "1011", f_name: "Jordan", l_name: "Spieth") }
  let(:golfer12) { create(:golfer, source_id: "1012", f_name: "Brooks", l_name: "Koepka") }
  let(:golfer13) { create(:golfer, source_id: "1013", f_name: "Dustin", l_name: "Johnson") }
  let(:golfer14) { create(:golfer, source_id: "1014", f_name: "Bryson", l_name: "DeChambeau") }
  let(:golfer15) { create(:golfer, source_id: "1015", f_name: "Cameron", l_name: "Smith") }
  let(:golfer16) { create(:golfer, source_id: "1016", f_name: "Will", l_name: "Zalatoris") }

  describe "#calculate" do
    context "basic placement calculation" do
      it "calculates user placements based on total strokes" do
        # User 0: Best total (280 strokes) = 1st place = -4 points
        match_pick_1 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer1, drafted: true)
        match_pick_2 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer2, drafted: true)
        match_pick_3 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer3, drafted: true)
        match_pick_4 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer4, drafted: true)

        # User 0's scores: 70x4 = 280 strokes
        create(:score, match_pick: match_pick_1, round: 1, score: 70, status: "complete")
        create(:score, match_pick: match_pick_1, round: 2, score: 70, status: "complete")
        create(:score, match_pick: match_pick_1, round: 3, score: 70, status: "complete")
        create(:score, match_pick: match_pick_1, round: 4, score: 70, status: "complete")
        create(:score, match_pick: match_pick_2, round: 1, score: 70, status: "complete")
        create(:score, match_pick: match_pick_2, round: 2, score: 70, status: "complete")
        create(:score, match_pick: match_pick_2, round: 3, score: 70, status: "complete")
        create(:score, match_pick: match_pick_2, round: 4, score: 70, status: "complete")
        create(:score, match_pick: match_pick_3, round: 1, score: 70, status: "complete")
        create(:score, match_pick: match_pick_3, round: 2, score: 70, status: "complete")
        create(:score, match_pick: match_pick_3, round: 3, score: 70, status: "complete")
        create(:score, match_pick: match_pick_3, round: 4, score: 70, status: "complete")
        create(:score, match_pick: match_pick_4, round: 1, score: 70, status: "complete")
        create(:score, match_pick: match_pick_4, round: 2, score: 70, status: "complete")
        create(:score, match_pick: match_pick_4, round: 3, score: 70, status: "complete")
        create(:score, match_pick: match_pick_4, round: 4, score: 70, status: "complete")

        # User 1: Second best (284 strokes) = 2nd place = -3 points
        match_pick_5 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer5, drafted: true)
        match_pick_6 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer6, drafted: true)
        match_pick_7 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer7, drafted: true)
        match_pick_8 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer8, drafted: true)

        # User 1's scores: 71x4 = 284 strokes
        (1..4).each do |round|
          create(:score, match_pick: match_pick_5, round: round, score: 71, status: "complete")
          create(:score, match_pick: match_pick_6, round: round, score: 71, status: "complete")
          create(:score, match_pick: match_pick_7, round: round, score: 71, status: "complete")
          create(:score, match_pick: match_pick_8, round: round, score: 71, status: "complete")
        end

        # User 2: Third best (288 strokes) = 3rd place = -2 points
        match_pick_9 = create(:match_pick, user: users[2], tournament: tournament, golfer: golfer9, drafted: true)
        match_pick_10 = create(:match_pick, user: users[2], tournament: tournament, golfer: golfer10, drafted: true)
        match_pick_11 = create(:match_pick, user: users[2], tournament: tournament, golfer: golfer11, drafted: true)
        match_pick_12 = create(:match_pick, user: users[2], tournament: tournament, golfer: golfer12, drafted: true)

        # User 2's scores: 72x4 = 288 strokes
        (1..4).each do |round|
          create(:score, match_pick: match_pick_9, round: round, score: 72, status: "complete")
          create(:score, match_pick: match_pick_10, round: round, score: 72, status: "complete")
          create(:score, match_pick: match_pick_11, round: round, score: 72, status: "complete")
          create(:score, match_pick: match_pick_12, round: round, score: 72, status: "complete")
        end

        # User 3: Worst (292 strokes) = 4th place = -1 points
        match_pick_13 = create(:match_pick, user: users[3], tournament: tournament, golfer: golfer13, drafted: true)
        match_pick_14 = create(:match_pick, user: users[3], tournament: tournament, golfer: golfer14, drafted: true)
        match_pick_15 = create(:match_pick, user: users[3], tournament: tournament, golfer: golfer15, drafted: true)
        match_pick_16 = create(:match_pick, user: users[3], tournament: tournament, golfer: golfer16, drafted: true)

        # User 3's scores: 73x4 = 292 strokes
        (1..4).each do |round|
          create(:score, match_pick: match_pick_13, round: round, score: 73, status: "complete")
          create(:score, match_pick: match_pick_14, round: round, score: 73, status: "complete")
          create(:score, match_pick: match_pick_15, round: round, score: 73, status: "complete")
          create(:score, match_pick: match_pick_16, round: round, score: 73, status: "complete")
        end

        service = described_class.new(tournament)
        service.calculate

        results = MatchResult.where(tournament: tournament).order(:place)

        expect(results.count).to eq(4)

        # User 0: 1st place = -4 points
        expect(results[0].user_id).to eq(users[0].id)
        expect(results[0].place).to eq(1)
        expect(results[0].total_score).to eq(-4)

        # User 1: 2nd place = -3 points
        expect(results[1].user_id).to eq(users[1].id)
        expect(results[1].place).to eq(2)
        expect(results[1].total_score).to eq(-3)

        # User 2: 3rd place = -2 points
        expect(results[2].user_id).to eq(users[2].id)
        expect(results[2].place).to eq(3)
        expect(results[2].total_score).to eq(-2)

        # User 3: 4th place = -1 points
        expect(results[3].user_id).to eq(users[3].id)
        expect(results[3].place).to eq(4)
        expect(results[3].total_score).to eq(-1)
      end
    end

    context "major tournament bonus" do
      it "adds -2 bonus to winner in major championship" do
        # Create major championship tournament
        major_tournament = create(:tournament, tournament_id: "480", name: "Masters", major_championship: true)

        # User 0: Winner with major bonus = -4 + -2 = -6
        match_pick_1 = create(:match_pick, user: users[0], tournament: major_tournament, golfer: golfer1, drafted: true)
        (1..4).each { |round| create(:score, match_pick: match_pick_1, round: round, score: 68, status: "complete") }

        # User 1: Second place (no major bonus for non-winners) = -3
        match_pick_2 = create(:match_pick, user: users[1], tournament: major_tournament, golfer: golfer2, drafted: true)
        (1..4).each { |round| create(:score, match_pick: match_pick_2, round: round, score: 70, status: "complete") }

        service = described_class.new(major_tournament)
        service.calculate

        results = MatchResult.where(tournament: major_tournament).order(:place)

        # Winner gets -4 (1st place) + -2 (major bonus) = -6
        expect(results.first.total_score).to eq(-6)

        # Second place gets only -3 (no major bonus)
        expect(results.second.total_score).to eq(-3)
      end
    end

    context "winner picked bonus" do
      it "adds -1 bonus if user drafted tournament winner" do
        # Create a winner golfer (lowest score across ALL users)
        winner_golfer = create(:golfer, source_id: "9999", f_name: "Tournament", l_name: "Winner")

        # User 0: Drafted winner, finishes 2nd place in user standings
        match_pick_1 = create(:match_pick, user: users[0], tournament: tournament, golfer: winner_golfer, drafted: true)
        match_pick_2 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer2, drafted: true)

        # Winner golfer has amazing score (260 total)
        (1..4).each { |round| create(:score, match_pick: match_pick_1, round: round, score: 65, status: "complete") }
        # User 0's other golfer has okay score
        (1..4).each { |round| create(:score, match_pick: match_pick_2, round: round, score: 72, status: "complete") }
        # User 0 total: 260 + 288 = 548 strokes

        # User 1: Did NOT draft winner, finishes 1st place in user standings (lower total)
        match_pick_3 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer3, drafted: true)
        match_pick_4 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer4, drafted: true)

        # Both golfers have good but not amazing scores (266 total each)
        (1..4).each { |round| create(:score, match_pick: match_pick_3, round: round, score: 66, status: "complete") }
        (1..4).each { |round| create(:score, match_pick: match_pick_4, round: round, score: 67, status: "complete") }
        # User 1 total: 264 + 268 = 532 strokes (wins user standings)

        service = described_class.new(tournament)
        service.calculate

        results = MatchResult.where(tournament: tournament).index_by(&:user_id)

        # User 1: 1st place = -4 points, no winner picked
        expect(results[users[1].id].total_score).to eq(-4)
        expect(results[users[1].id].winner_picked).to be false

        # User 0: 2nd place = -3 points, + winner picked bonus = -1, total = -4
        expect(results[users[0].id].total_score).to eq(-4)
        expect(results[users[0].id].winner_picked).to be true
      end
    end

    context "cuts missed tracking" do
      it "tracks number of drafted golfers who were cut" do
        # User 0: Has 2 golfers cut, 2 golfers complete
        match_pick_1 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer1, drafted: true)
        match_pick_2 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer2, drafted: true)
        match_pick_3 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer3, drafted: true)
        match_pick_4 = create(:match_pick, user: users[0], tournament: tournament, golfer: golfer4, drafted: true)

        # Golfer 1: Complete (rounds 1-4)
        (1..4).each { |round| create(:score, match_pick: match_pick_1, round: round, score: 70, status: "complete") }

        # Golfer 2: Cut (rounds 1-2, then 1→3, 2→4 copied)
        create(:score, match_pick: match_pick_2, round: 1, score: 76, status: "cut")
        create(:score, match_pick: match_pick_2, round: 2, score: 77, status: "cut")
        create(:score, match_pick: match_pick_2, round: 3, score: 76, status: "cut") # Copied from round 1
        create(:score, match_pick: match_pick_2, round: 4, score: 77, status: "cut") # Copied from round 2

        # Golfer 3: Cut
        create(:score, match_pick: match_pick_3, round: 1, score: 78, status: "cut")
        create(:score, match_pick: match_pick_3, round: 2, score: 79, status: "cut")
        create(:score, match_pick: match_pick_3, round: 3, score: 78, status: "cut")
        create(:score, match_pick: match_pick_3, round: 4, score: 79, status: "cut")

        # Golfer 4: Complete
        (1..4).each { |round| create(:score, match_pick: match_pick_4, round: round, score: 71, status: "complete") }

        # User 1: No cuts
        match_pick_5 = create(:match_pick, user: users[1], tournament: tournament, golfer: golfer5, drafted: true)
        (1..4).each { |round| create(:score, match_pick: match_pick_5, round: round, score: 70, status: "complete") }

        service = described_class.new(tournament)
        service.calculate

        results = MatchResult.where(tournament: tournament).index_by(&:user_id)

        # User 0: 2 cuts (golfers 2 and 3)
        expect(results[users[0].id].cuts_missed).to eq(2)

        # User 1: 0 cuts
        expect(results[users[1].id].cuts_missed).to eq(0)
      end
    end
  end
end
