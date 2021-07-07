class AddParentUuidsToQuestionsGroupsAndSections < ActiveRecord::Migration
  def change
    add_column :sections, :master_section_uuid, :string
    add_column :groups, :master_group_uuid, :string
    add_column :questions, :master_question_uuid, :string
    add_column :rules, :master_rule_uuid, :string
  end
end
