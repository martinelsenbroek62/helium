class AddInvalidFlagToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :valid_survey, :boolean, default: true
  end
end
