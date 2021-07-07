class AddHeadersForClaimsExportToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :headers_for_claims_export_agg, :string
  end
end
