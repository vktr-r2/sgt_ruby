class Golfer < ApplicationRecord
  belongs_to :tournament, foreign_key: "last_active_tourney", primary_key: "unique_id"
end
