class AddAdminBoolToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin, :boolean, default: false, null: false

    # Update existing records
    User.where(email: "vik.ristic@gmail.com").update_all(admin: true)
    User.where.not(email: "vik.ristic@gmail.com").update_all(admin: false)
  end
end
