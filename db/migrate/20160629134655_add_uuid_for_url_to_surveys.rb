class AddUuidForUrlToSurveys < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_uuid, :string
    add_column :users, :username, :string

    add_index :surveys, :survey_uuid
    add_index :users, :username
  end
end
