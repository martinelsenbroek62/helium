class AddRequestingAmountToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :requesting_amount, :string
  end
end
