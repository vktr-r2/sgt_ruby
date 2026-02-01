class LeaderboardSnapshot < ApplicationRecord
  belongs_to :tournament

  validates :tournament_id, presence: true
  validates :leaderboard_data, presence: true
  validates :fetched_at, presence: true

  # Delete snapshots for other tournaments when saving a new one
  # This ensures we only keep data for the current tournament
  def self.save_snapshot(tournament:, leaderboard_data:, current_round:, cut_line_score:, cut_line_count:)
    transaction do
      # Delete all existing snapshots (keeps only current tournament)
      where.not(tournament_id: tournament.id).delete_all

      # Find or create snapshot for this tournament
      snapshot = find_or_initialize_by(tournament_id: tournament.id)
      snapshot.update!(
        leaderboard_data: leaderboard_data,
        current_round: current_round,
        cut_line_score: cut_line_score,
        cut_line_count: cut_line_count,
        fetched_at: Time.current
      )
      snapshot
    end
  end
end
