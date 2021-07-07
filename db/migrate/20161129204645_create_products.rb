class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.integer :organization_id
      t.string :focus_area
      t.string :category_name
      t.string :product_type
      t.string :name
      t.string :description
      t.string :image_url
      t.string :reimbursement_percentage

      t.timestamps null: false
    end

    add_column :claims, :product_id, :integer
  end
end
