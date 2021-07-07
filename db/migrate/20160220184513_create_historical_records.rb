class CreateHistoricalRecords < ActiveRecord::Migration
  def change
    create_table :historical_records do |t|
      t.integer :survey_id
      t.integer :user_id
      t.json :data
      t.integer :year

      t.timestamps null: false
    end
  end
end
