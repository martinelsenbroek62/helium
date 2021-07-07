class AddUuidToClaimAttachments < ActiveRecord::Migration
  def change
    add_column :claim_attachments, :uuid, :string
  end
end
