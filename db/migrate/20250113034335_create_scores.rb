class CreateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :scores do |t|
      t.references :match_pick, foreign_key: { on_delete: :cascade }
      t.integer :score, null: true, default: 0
      t.integer :round, null: true, default: 1
      t.timestamps
    end
  end
end
