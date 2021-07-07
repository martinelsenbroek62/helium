class AddSurveyTimestampsToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :completed_at, :timestamp
    add_column :surveys, :started_at, :timestamp
  end
end
