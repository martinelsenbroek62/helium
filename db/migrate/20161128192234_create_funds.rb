class CreateFunds < ActiveRecord::Migration
  def change
    create_table :funds do |t|
      t.integer :user_id
      t.integer :organization_id
      t.integer :amount
      t.date :expires_on

      t.timestamps null: false
    end
  end
end
