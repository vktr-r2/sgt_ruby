class Tournament < ApplicationRecord
  validates :tournament_id, presence: true
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :week_number, presence: true
  validates :year, presence: true
  validates :format, presence: true

  # Associations
  has_many :players, foreign_key: "last_active_tourney", primary_key: "unique_id"
  has_many :match_picks, foreign_key: "tournament_id", primary_key: "id", dependent: :destroy
  has_many :match_results, dependent: :destroy

  def draft_window_start
    # Two days before tournament starts at 00:00:00
    (start_date - 2.days).beginning_of_day
  end

  def draft_window_end
    # One day before tournament starts at 23:59:59
    (start_date - 1.day).end_of_day
  end

  def draft_window_open?(current_time = Time.zone.now)
    current_time >= draft_window_start && current_time <= draft_window_end
  end
end
