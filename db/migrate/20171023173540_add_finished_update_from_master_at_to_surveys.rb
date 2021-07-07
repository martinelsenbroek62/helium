class AddFinishedUpdateFromMasterAtToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :finished_updating_from_master_at, :timestamp
  end
end
