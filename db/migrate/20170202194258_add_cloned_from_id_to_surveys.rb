class AddClonedFromIdToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :cloned_from_id, :integer
  end
end
