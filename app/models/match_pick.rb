class MatchPick < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :golfer
  has_many :scores, dependent: :destroy

  # Golfer selection limit per season (Scottie Scheffler rule)
  GOLFER_SELECTION_LIMIT = 3

  # Score-related methods
  def total_score
    scores.sum(:score)
  end

  def score_for_round(round_number)
    scores.find_by(round: round_number)&.score
  end

  def scores_by_round
    scores.ordered_by_round.pluck(:round, :score).to_h
  end

  def completed_rounds
    scores.count
  end

  def has_completed_round?(round_number)
    scores.exists?(round: round_number)
  end
end
