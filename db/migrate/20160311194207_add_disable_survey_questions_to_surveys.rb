class AddDisableSurveyQuestionsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :allowed_to_submit_answers, :boolean, default: true
  end
end
