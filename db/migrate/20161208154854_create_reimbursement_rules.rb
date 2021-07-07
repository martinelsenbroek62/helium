class CreateReimbursementRules < ActiveRecord::Migration
  def change
    create_table :reimbursement_rules do |t|
      t.integer :organization_id
      t.string :focus_area
      t.string :category_name
      t.string :percentage

      t.timestamps null: false
    end
  end
end
