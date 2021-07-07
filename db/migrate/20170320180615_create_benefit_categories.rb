class CreateBenefitCategories < ActiveRecord::Migration
  def change
    create_table :benefit_categories do |t|
      t.integer :organization_id
      t.string :uuid
      t.string :name
      t.string :focus_area
      t.string :product_type

      t.string :percent_to_reimburse

      t.text :description
      t.text :focus_area_description
      t.text :product_type_description


      t.timestamps null: false
    end
  end
end
