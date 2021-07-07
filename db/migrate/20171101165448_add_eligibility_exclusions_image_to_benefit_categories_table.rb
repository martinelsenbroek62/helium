class AddEligibilityExclusionsImageToBenefitCategoriesTable < ActiveRecord::Migration
  def change
    add_column :benefit_categories, :eligibility_description, :text
    add_column :benefit_categories, :description_of_exclusions, :text
    add_column :benefit_categories, :benefit_category_image_url, :string
  end
end
