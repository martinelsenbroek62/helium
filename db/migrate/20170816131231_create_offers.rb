class CreateOffers < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.string :uuid
      t.integer :organization_id
      t.string :company
      t.string :name
      t.text :body
      t.string :website
      t.date :start_date
      t.date :end_date
      t.string :cta
      t.string :value
      t.boolean :published, default:false

      t.timestamps null: false
    end
  end
end
