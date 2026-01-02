class AddReplacementTrackingToMatchPicks < ActiveRecord::Migration[8.0]
  def change
    add_column :match_picks, :original_golfer_id, :bigint, default: nil
    add_column :match_picks, :replaced_at_round, :integer, default: nil
    add_column :match_picks, :replacement_reason, :string, default: nil

    add_index :match_picks, :original_golfer_id
    add_foreign_key :match_picks, :golfers, column: :original_golfer_id, on_delete: :nullify
  end
end
