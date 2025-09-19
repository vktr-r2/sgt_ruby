class AddScoresConstraintsAndIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add unique constraint to prevent duplicate scores for same match_pick + round
    add_index :scores, [:match_pick_id, :round], unique: true, name: "index_scores_on_match_pick_and_round"
    
    # Add check constraint to ensure valid round numbers (1-4)
    add_check_constraint :scores, "round >= 1 AND round <= 4", name: "valid_round_range"
    
    # Performance indexes for common aggregation queries
    
    # For fast SUM(score) queries grouped by match_pick_id
    add_index :scores, [:match_pick_id, :score], name: "index_scores_on_match_pick_and_score"
    
    # For round-specific queries (e.g., "show all round 1 scores")
    add_index :scores, [:round, :score], name: "index_scores_on_round_and_score"
    
    # For tournament leaderboards - join through match_picks to tournaments
    # This requires composite index on match_picks first
    add_index :match_picks, [:tournament_id, :user_id, :golfer_id], name: "index_match_picks_tournament_user_golfer"
  end
end
