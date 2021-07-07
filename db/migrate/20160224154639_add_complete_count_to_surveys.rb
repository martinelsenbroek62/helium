class AddCompleteCountToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :finish_number, :integer, default: nil
  end
end
