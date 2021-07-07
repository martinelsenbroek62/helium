class AddApprovedToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :approved, :boolean, default:false
    add_column :claims, :rejected, :boolean, default:false
  end
end
