class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.integer :answer_from_id
      t.integer :question_id
      t.integer :group_id

      t.string :operator
      t.string :value

      t.timestamps null: false
    end

    add_column :questions, :show, :boolean, default: true
    add_column :groups, :show, :boolean, default: true
  end
end
