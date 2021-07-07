class AddSurveyAndBenefitsBooleansToOrganizers < ActiveRecord::Migration
  def change
    add_column :organizations, :has_surveys, :boolean, default: false
    add_column :organizations, :has_benefits, :boolean, default: false
  end
end
