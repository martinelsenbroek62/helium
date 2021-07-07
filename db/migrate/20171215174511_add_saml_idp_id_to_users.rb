class AddSamlIdpIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :saml_idp, :string
    add_column :users, :saml_idp_id, :string
  end
end
