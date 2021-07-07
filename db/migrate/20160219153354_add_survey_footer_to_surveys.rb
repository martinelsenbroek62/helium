class AddSurveyFooterToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_footer_template, :text
  end
end
