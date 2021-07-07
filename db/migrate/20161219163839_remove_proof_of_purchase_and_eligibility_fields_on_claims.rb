class RemoveProofOfPurchaseAndEligibilityFieldsOnClaims < ActiveRecord::Migration
  def change
    remove_column :claims, :proof_of_purchase, :json
    remove_column :claims, :proof_eligibility, :json
  end
end
