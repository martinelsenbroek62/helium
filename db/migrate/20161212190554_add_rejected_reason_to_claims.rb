class AddRejectedReasonToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :rejected_reason, :string
  end
end
