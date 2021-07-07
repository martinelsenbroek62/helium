class AddHistoricalFlagToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :historical, :boolean, default: false
  end
end
