class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.string :uuid
      t.integer :organization_id
      t.integer :user_id
      t.integer :author_id
      t.integer :claim_id
      t.text :body

      t.timestamps null: false
    end
  end
end
