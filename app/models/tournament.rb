class Tournament < ApplicationRecord
  validates :tournament_id, presence: true
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :week_number, presence: true
  validates :year, presence: true
  validates :format, presence: true
end

# should probably consider allowing null for all fields not mentioned above
# Also, should there be one service that handles imports for tournaments, and it can dynamically handle both schedule and tournament inserts?
#
