class AddProofOfPurchaseToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :proof_of_purchase, :json
  end
end
