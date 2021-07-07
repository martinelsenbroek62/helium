class AddShowPreviousAnswersToSurveyQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :show_previous_answers, :boolean, default: false
  end
end
