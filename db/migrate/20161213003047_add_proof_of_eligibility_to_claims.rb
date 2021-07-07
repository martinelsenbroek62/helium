class AddProofOfEligibilityToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :proof_eligibility, :json
  end
end
