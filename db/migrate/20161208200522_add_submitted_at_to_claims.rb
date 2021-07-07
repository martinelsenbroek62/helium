class AddSubmittedAtToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :submitted_at, :timestamp
  end
end
