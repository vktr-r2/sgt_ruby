class Score < ApplicationRecord
  belongs_to :match_pick
  
  validates :score, presence: true, numericality: { only_integer: true }
  validates :round, presence: true, inclusion: { in: 1..4 }
  validates :match_pick_id, uniqueness: { scope: :round, message: "already has a score for this round" }
  
  scope :for_round, ->(round_number) { where(round: round_number) }
  scope :ordered_by_round, -> { order(:round) }
end
