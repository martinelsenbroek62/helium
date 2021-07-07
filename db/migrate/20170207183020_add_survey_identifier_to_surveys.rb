class AddSurveyIdentifierToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_identifier, :string
  end
end
