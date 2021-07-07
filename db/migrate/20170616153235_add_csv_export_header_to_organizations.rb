class AddCsvExportHeaderToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :headers_for_claims_export, :string
  end
end
