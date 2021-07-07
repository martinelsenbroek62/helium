class CreateBenefitPrograms < ActiveRecord::Migration
  def change
    create_table :benefit_programs do |t|
      t.string :uuid
      t.string :name
      t.integer :organization_id
      t.text :description
      t.timestamps null: false
    end
  end
end
