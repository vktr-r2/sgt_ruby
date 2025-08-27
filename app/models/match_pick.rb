class MatchPick < ApplicationRecord
  belongs_to :user
  belongs_to :tournament
  belongs_to :golfer
end
