class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.integer :organization_id
      t.integer :user_id
      t.integer :master_id
      t.string :name
      t.string :spreadsheet
      t.boolean :has_reached_end, default: false
      t.boolean :complete, default: false

      t.text :start_template
      t.text :complete_template

      t.text :section_template
      t.text :section_start_template
      t.text :section_complete_template
      t.text :group_template
      t.text :question_template
      t.text :faq_template
      t.text :analytics_template

      t.text :report_template
      t.text :report_style_template
      t.text :report_script_template

      t.text :styles_template
      t.text :invite_template

      t.timestamps null: false
    end
  end
end
