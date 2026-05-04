class AddConcludedToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :concluded, :boolean, default: false, null: false
    # Backfill: past tournaments (end_date before today) are considered concluded
    reversible do |dir|
      dir.up { Tournament.where("end_date < ?", Date.current).update_all(concluded: true) }
    end
  end
end
