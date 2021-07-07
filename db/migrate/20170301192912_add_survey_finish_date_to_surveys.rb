class AddSurveyFinishDateToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :finish_date, :date
  end
end
