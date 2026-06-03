require "rails_helper"

RSpec.describe BusinessLogic::TiebreakerService do
  def data(round_scores:, drafted_winner: false)
    { round_scores: round_scores, drafted_winner: drafted_winner }
  end

  describe ".compare" do
    context "rule a: best round score" do
      it "returns -1 when user_a has a lower best round score" do
        a = data(round_scores: [64, 67, 68, 69])
        b = data(round_scores: [65, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "returns 1 when user_b has a lower best round score" do
        a = data(round_scores: [66, 67, 68, 69])
        b = data(round_scores: [64, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(1)
      end
    end

    context "rule b: winner picked (when best round scores are equal)" do
      it "returns -1 when user_a picked the winner and user_b did not" do
        a = data(round_scores: [64, 67, 68, 69], drafted_winner: true)
        b = data(round_scores: [64, 67, 68, 69], drafted_winner: false)
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "returns 1 when user_b picked the winner and user_a did not" do
        a = data(round_scores: [64, 67, 68, 69], drafted_winner: false)
        b = data(round_scores: [64, 67, 68, 69], drafted_winner: true)
        expect(described_class.compare(a, b)).to eq(1)
      end
    end

    context "rules c+: 2nd, 3rd, 4th best round scores" do
      it "uses 2nd best round when 1st scores and winner_picked are equal" do
        a = data(round_scores: [64, 65, 68, 69])
        b = data(round_scores: [64, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "uses 3rd best round when 1st and 2nd scores are equal" do
        a = data(round_scores: [64, 67, 66, 69])
        b = data(round_scores: [64, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(-1)
      end

      it "uses 4th best round as further comparison" do
        a = data(round_scores: [64, 67, 68, 65])
        b = data(round_scores: [64, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(-1)
      end
    end

    context "rule f: complete tie" do
      it "returns 0 when all round scores are equal and neither picked the winner" do
        a = data(round_scores: [64, 67, 68, 69])
        b = data(round_scores: [64, 67, 68, 69])
        expect(described_class.compare(a, b)).to eq(0)
      end
    end

    context "winner_picked rule applied mid-comparison" do
      it "applies winner_picked check after rule a, not after all round comparisons" do
        # Rule a tied (both 64), rule b: a picked winner → a wins before reaching rule c
        a = data(round_scores: [64, 60, 60, 60], drafted_winner: true)
        b = data(round_scores: [64, 70, 72, 74], drafted_winner: false)
        # Even though b has worse 2nd/3rd/4th rounds, rule b fires first → a wins
        expect(described_class.compare(a, b)).to eq(-1)
      end
    end
  end
end
