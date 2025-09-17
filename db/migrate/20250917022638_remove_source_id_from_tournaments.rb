class RemoveSourceIdFromTournaments < ActiveRecord::Migration[8.0]
  def change
    remove_index :tournaments, :source_id
    remove_column :tournaments, :source_id, :string
  end
end
