class AddNotYetStartedToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :has_started, :boolean, default: false
  end
end
