class AddPaidOutToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :paid_out, :boolean, default: false
    add_column :reimbursement_rules, :kind, :string
    add_column :products, :kind, :string
    add_column :funds, :comment, :string

    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :employee_id, :string
    add_column :users, :employee_start_date, :date
    add_column :users, :employee_termination_date, :date
    add_column :users, :employee_office_location, :string
    add_column :users, :employee_state_of_residence, :string
  end
end
