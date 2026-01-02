class AddPositionAndStatusToScores < ActiveRecord::Migration[8.0]
  def change
    add_column :scores, :position, :string, default: nil
    add_column :scores, :status, :string, default: "active"

    add_index :scores, :status
  end
end
