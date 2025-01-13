class CreateTournaments < ActiveRecord::Migration[8.0]
  def change
    create_table :tournaments do |t|
      t.string :tournament_id, null: true, default: ""
      t.string :source_id, null: false, default: ""
      t.string :name, null: false, default: ""
      t.integer :year, null: false
      t.string :golf_course, null: false, default: ""
      t.json :location, null: false
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.integer :week_number, null: false
      t.string :time_zone, null: true, default: ""
      t.string :format, null: false, default: "stroke"
      t.boolean :major_championship, null: false, default: false
      t.timestamps
    end
    add_index :tournaments, :source_id
    add_index :tournaments, [ :tournament_id, :year ]
  end
end
