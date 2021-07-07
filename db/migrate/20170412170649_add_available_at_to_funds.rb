class AddAvailableAtToFunds < ActiveRecord::Migration
  def change
    add_column :funds, :available_on, :date
  end
end
