class AddAssociationsToBenefitProgramsAndCategories < ActiveRecord::Migration
  def change
    add_column :claims, :benefit_program_id, :integer
    add_column :claims, :benefit_category_id, :integer
    add_column :benefit_categories, :benefit_program_id, :integer
  end
end
