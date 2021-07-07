class CreateClaimAttachments < ActiveRecord::Migration
  def change
    create_table :claim_attachments do |t|
      t.integer :claim_id
      t.integer :user_id
      t.integer :organization_id
      t.string :kind
      t.json :attachment

      t.timestamps null: false
    end
  end
end
