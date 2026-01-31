class CreateLeaderboardSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :leaderboard_snapshots do |t|
      t.references :tournament, null: false, foreign_key: true
      t.jsonb :leaderboard_data
      t.integer :current_round
      t.string :cut_line_score
      t.integer :cut_line_count
      t.datetime :fetched_at

      t.timestamps
    end
  end
end
