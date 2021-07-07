class AddSurveyResultsVariableMapToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_results_variables_map, :text
  end
end
