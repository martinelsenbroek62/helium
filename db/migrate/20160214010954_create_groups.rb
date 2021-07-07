class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.integer :section_id
      t.string :name

      t.string :intro
      t.integer :position

      t.text :more_info
      t.text :template

      t.timestamps null: false
    end
  end
end
