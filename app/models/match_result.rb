class MatchResult < ApplicationRecord
  # Associations
  belongs_to :tournament
  belongs_to :user

  # Validations
  validates :tournament_id, presence: true
  validates :user_id, presence: true
  validates :total_score, presence: true
  validates :place, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :cuts_missed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
