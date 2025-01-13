class CreateMatchPicks < ActiveRecord::Migration[8.0]
  def change
    create_table :match_picks do |t|
      t.references :user, foreign_key: { on_delete: :cascade }
      t.references :tournament, foreign_key: { on_delete: :cascade }
      t.references :golfer, foreign_key: { on_delete: :cascade }
      t.integer :priority, null: false
      t.boolean :drafted, null: true, default: false
      t.timestamps
    end
  end
end
