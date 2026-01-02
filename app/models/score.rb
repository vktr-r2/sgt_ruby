class Score < ApplicationRecord
  # Associations
  belongs_to :match_pick

  # Validations
  validates :match_pick_id, presence: true
  validates :score, presence: true, numericality: { only_integer: true }
  validates :round, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 4 }
  validates :status, inclusion: { in: %w[active complete cut wd], allow_nil: true }

  # Scopes
  scope :for_round, ->(round) { where(round: round) }
  scope :by_round, -> { order(:round) }
end
