class CreateGolfers < ActiveRecord::Migration[8.0]
  def change
    create_table :golfers do |t|
      t.string :source_id, null: false, default: ""
      t.string :f_name, null: false, default: ""
      t.string :l_name, null: false, default: ""
      t.string :last_active_tourney, null: false, default: ""
      t.timestamps
    end
    add_index :golfers, :source_id
  end
end
