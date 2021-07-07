class AddHasSelfSignupToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :has_self_signup, :boolean, default: false
    add_column :organizations, :signup_slug, :string
    add_column :surveys, :create_on_self_signup, :boolean, default:false
  end
end
