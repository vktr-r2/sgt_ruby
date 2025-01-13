class CreateMatchResults < ActiveRecord::Migration[8.0]
  def change
    create_table :match_results do |t|
      t.references :tournament, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :total_score, null: false
      t.integer :place, null: false
      t.boolean :winner_picked, null: false, default: false
      t.integer :cuts_missed, null: false, default: 0
      t.timestamps null: false
    end
  end
end
