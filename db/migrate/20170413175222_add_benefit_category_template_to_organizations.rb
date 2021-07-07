class AddBenefitCategoryTemplateToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :benefit_categories_template, :text
  end
end
