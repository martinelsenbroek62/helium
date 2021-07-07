class AddBenefitFieldsForOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :logo, :json
    add_column :organizations, :benefit_welcome, :text
    add_column :organizations, :benefit_balance, :text
    add_column :organizations, :benefit_focus_area, :text
    add_column :organizations, :benefit_claims_form, :text
  end
end
