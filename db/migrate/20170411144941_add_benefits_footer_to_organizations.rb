class AddBenefitsFooterToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :benefit_footer, :text
  end
end
