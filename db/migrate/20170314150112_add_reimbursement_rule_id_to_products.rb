class AddReimbursementRuleIdToProducts < ActiveRecord::Migration
  def change
    add_column :products, :reimbursement_rule_id, :integer
  end
end
