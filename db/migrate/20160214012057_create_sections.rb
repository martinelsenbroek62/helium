class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.string :name
      t.integer :position

      t.text :more_info
      t.text :template

      t.timestamps null: false
    end
  end
end
