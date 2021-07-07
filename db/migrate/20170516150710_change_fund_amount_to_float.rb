class ChangeFundAmountToFloat < ActiveRecord::Migration
  def change
    change_column :funds, :amount, :float
  end
end
