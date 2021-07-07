class CreateUserFields < ActiveRecord::Migration
  def change
    create_table :user_fields do |t|
      t.integer :user_id
      t.integer :organization_id
      t.integer :master_survey_id
      t.json :data

      t.timestamps null: false
    end
  end
end
