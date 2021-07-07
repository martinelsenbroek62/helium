class AddCategoryNotesToBenefitCategoriesTable < ActiveRecord::Migration
  def change
    add_column :benefit_categories, :category_notes, :text
  end
end
