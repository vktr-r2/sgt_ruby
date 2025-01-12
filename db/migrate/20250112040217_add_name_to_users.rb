class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string, null: false

    # Update existing records to set the default value
    reversible do |dir|
      dir.up do
        User.update_all(name: "J Doe")
      end
    end
  end
end