class AddTemplateForBenefitCategoriesPageToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :benefit_categories_text, :text
  end
end
