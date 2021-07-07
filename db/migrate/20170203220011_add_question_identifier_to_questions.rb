class AddQuestionIdentifierToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :question_identifier, :string
  end
end
