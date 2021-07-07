class AddDescriptionsToRules < ActiveRecord::Migration
  def change
    add_column :reimbursement_rules, :focus_area_description, :text
    add_column :reimbursement_rules, :category_name_description, :text
  end
end
