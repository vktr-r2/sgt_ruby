class AddThruToScores < ActiveRecord::Migration[8.0]
  def change
    add_column :scores, :thru, :string
  end
end
