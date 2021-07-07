class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name

      t.text :organization_styles_template

      t.timestamps null: false
    end
  end
end
