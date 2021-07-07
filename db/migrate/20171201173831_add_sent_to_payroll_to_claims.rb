class AddSentToPayrollToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :sent_to_payroll, :boolean, default:false
  end
end
