class AddMoreIndexesToForeignKeys < ActiveRecord::Migration
  def change
    add_index :questions, :organization_id
    add_index :questions, :survey_id
    add_index :questions, :group_id
    add_index :questions, :section_id
    add_index :questions, :position

    add_index :groups, :organization_id
    add_index :groups, :survey_id
    add_index :groups, :section_id
    add_index :groups, :position

    add_index :sections, :organization_id
    add_index :sections, :survey_id
    add_index :sections, :position

    add_index :surveys, :organization_id
    add_index :surveys, :master_id
    add_index :surveys, :user_id

    add_index :rules, :organization_id
    add_index :rules, :survey_id
    add_index :rules, :answer_from_id
    add_index :rules, :question_id
    add_index :rules, :group_id
  end
end
