class MatchPick < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :tournament
  belongs_to :golfer
  has_many :scores, dependent: :destroy

  # Golfer selection limit per season (Scottie Scheffler rule)
  GOLFER_SELECTION_LIMIT = 3
end
