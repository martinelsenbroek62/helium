class AddEmployeeInviteToUsers < ActiveRecord::Migration
  def change
    add_column :users, :employee_invite_uuid, :string
    add_column :users, :employee_accepted_invite_at, :datetime
  end
end
