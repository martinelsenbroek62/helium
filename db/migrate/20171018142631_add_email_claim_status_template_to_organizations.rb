class AddEmailClaimStatusTemplateToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :email_claim_status_template, :text
  end
end
