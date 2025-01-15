class AddParToTournaments < ActiveRecord::Migration[8.0]
  def change
    add_column :tournaments, :par, :integer, null: false, default: 72

    reversible do |dir|
      dir.up do
        Tournament.update_all(par: 72)
      end
    end
  end
end
