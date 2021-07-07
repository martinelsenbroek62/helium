class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.string :uuid
      t.string :key
      t.string :value

      t.timestamps null: false
    end
  end
end
