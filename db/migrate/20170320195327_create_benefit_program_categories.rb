class CreateBenefitProgramCategories < ActiveRecord::Migration
  def change
    create_table :benefit_program_categories do |t|
      t.string :uuid
      t.integer :benefit_program_id
      t.integer :benefit_category_id

      t.timestamps null: false
    end
  end
end
