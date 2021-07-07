class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.integer :organization_id
      t.string :title
      t.string :slug
      t.text :body
      t.integer :position
      t.string :uuid
      t.boolean :published

      t.timestamps null: false
    end
  end
end
