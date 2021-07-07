class AddEmployeeWelcomeTextToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :employee_welcome_email_text, :text
  end
end
