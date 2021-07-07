class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :organization_id
      t.integer :survey_id
      t.string :uuid
      t.string :subject
      t.string :body
      t.string :deliver_to
      t.timestamp :delivered_at

      t.timestamps null: false
    end
  end
end
