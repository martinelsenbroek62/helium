class AddApprovedClaimNoteToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :approved_claim_note, :string
  end
end
