class AddOffersFeatureToggleToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :has_offers, :boolean, default:false
    add_column :benefit_programs, :program_notes, :text
    add_column :surveys, :survey_notes, :text
  end
end
