class Tournament < ApplicationRecord
  validates :tournament_id, presence: true
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :week_number, presence: true
  validates :year, presence: true
  validates :format, presence: true
  has_many :players, foreign_key: "last_active_tourney", primary_key: "unique_id"
  has_many :match_picks, foreign_key: "tournament_id", primary_key: "id", dependent: :destroy
end
