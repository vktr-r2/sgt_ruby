class MatchPick < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :golfer

  # Golfer selection limit per season (Scottie Scheffler rule)
  GOLFER_SELECTION_LIMIT = 3
end
