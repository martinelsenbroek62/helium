class CreateClaims < ActiveRecord::Migration
  def change
    create_table :claims do |t|
      t.integer :organization_id
      t.integer :created_by_id
      t.integer :user_id

      t.string :uuid
      t.string :title
      t.text :description
      t.date :expensed_date
      t.string :purchase_amount
      t.string :reimbursement_amount

      t.timestamps null: false
    end
  end
end
