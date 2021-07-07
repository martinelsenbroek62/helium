class AddSelfSignupPasswordToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :self_signup_password, :string
  end
end
