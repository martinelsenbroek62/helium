class AddParticipationGoalAndReportThresholdToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :report_threshold, :integer
    add_column :surveys, :participation_goal, :integer
  end
end
