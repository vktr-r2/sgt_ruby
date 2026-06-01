require "rails_helper"

RSpec.describe BusinessLogic::TiebreakerService do
  def data(golfer_totals:, drafted_winner: false)
    { golfer_totals: golfer_totals, drafted_winner: drafted_winner }
  end

  describe ".compare" do
    context "rule a: best golfer total" do
      it "returns -1 when user_a has a lower best golfer total" do
        a = data(golfer_totals: [268, 275, 280, 285])
        b = data(golfer_totals: [270, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "returns 1 when user_b has a lower best golfer total" do
        a = data(golfer_totals: [272, 275, 280, 285])
        b = data(golfer_totals: [268, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(1)
      end
    end

    context "rule b: winner picked (when best totals are equal)" do
      it "returns -1 when user_a picked the winner and user_b did not" do
        a = data(golfer_totals: [268, 275, 280, 285], drafted_winner: true)
        b = data(golfer_totals: [268, 275, 280, 285], drafted_winner: false)
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "returns 1 when user_b picked the winner and user_a did not" do
        a = data(golfer_totals: [268, 275, 280, 285], drafted_winner: false)
        b = data(golfer_totals: [268, 275, 280, 285], drafted_winner: true)
        expect(described_class.compare(a, b)).to eq(1)
      end
    end

    context "rules c-e: 2nd, 3rd, 4th golfer totals" do
      it "uses 2nd best golfer when 1st totals and winner_picked are equal" do
        a = data(golfer_totals: [268, 273, 280, 285])
        b = data(golfer_totals: [268, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "uses 3rd best golfer when 1st and 2nd totals are equal" do
        a = data(golfer_totals: [268, 275, 278, 285])
        b = data(golfer_totals: [268, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "uses 4th best golfer as final numeric comparison" do
        a = data(golfer_totals: [268, 275, 280, 283])
        b = data(golfer_totals: [268, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(-1)
      end
    end

    context "rule f: complete tie" do
      it "returns 0 when all four golfer totals are equal and neither picked the winner" do
        a = data(golfer_totals: [268, 275, 280, 285])
        b = data(golfer_totals: [268, 275, 280, 285])
        expect(described_class.compare(a, b)).to eq(0)
      end
    end

    context "winner_picked rule applied mid-comparison" do
      it "applies winner_picked check after rule a, not after all golfer comparisons" do
        # Rule a tied (both 268), rule b: a picked winner → a wins before reaching rule c
        a = data(golfer_totals: [268, 260, 260, 260], drafted_winner: true)
        b = data(golfer_totals: [268, 270, 280, 290], drafted_winner: false)
        # Even though b has worse 2nd/3rd/4th golfers, rule b fires first → a wins
        expect(described_class.compare(a, b)).to eq(-1)
      end
    end
  end
end
