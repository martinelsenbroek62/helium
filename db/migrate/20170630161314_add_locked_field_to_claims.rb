class AddLockedFieldToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :locked, :boolean, default: false
  end
end
