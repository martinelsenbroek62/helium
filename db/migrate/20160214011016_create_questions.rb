class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.integer :section_id
      t.integer :group_id
      t.string :text
      t.string :answer, default: ""
      t.integer :position, default:0

      t.string :key
      t.string :more_info
      t.string :kind
      t.string :options
      t.boolean :required, default:false
      t.string :cell
      t.string :units
      t.string :placeholder

      t.text :more_info
      t.text :template

      t.timestamps null: false
    end
  end
end
