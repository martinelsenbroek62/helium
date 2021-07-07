class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.integer :organization_id
      t.string :uuid
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.boolean :available, default: true

      t.timestamps null: false
    end

    add_column :claims, :program_id, :integer
    add_column :claims, :reimbursement_rule_id, :integer
    add_column :funds, :program_id, :integer
    add_column :products, :program_id, :integer
    add_column :reimbursement_rules, :program_id, :integer
  end
end
