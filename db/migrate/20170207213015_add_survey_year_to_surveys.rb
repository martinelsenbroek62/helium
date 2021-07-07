class AddSurveyYearToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_year, :integer
  end
end
