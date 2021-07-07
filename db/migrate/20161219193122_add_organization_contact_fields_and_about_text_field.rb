class AddOrganizationContactFieldsAndAboutTextField < ActiveRecord::Migration
  def change
    add_column :organizations, :benefit_about, :text
    add_column :organizations, :contact_name, :string
    add_column :organizations, :contact_phone, :string
    add_column :organizations, :contact_email, :string
  end
end
