class AddImageUrlToRemimbursementRules < ActiveRecord::Migration
  def change
    add_column :reimbursement_rules, :image_url, :string
  end
end
