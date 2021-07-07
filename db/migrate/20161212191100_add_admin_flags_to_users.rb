class AddAdminFlagsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :super_admin, :boolean, default: false
    add_column :users, :organization_admin, :boolean, default: false
  end
end
