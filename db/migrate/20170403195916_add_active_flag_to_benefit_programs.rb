class AddActiveFlagToBenefitPrograms < ActiveRecord::Migration
  def change
    add_column :benefit_programs, :active, :boolean, default: true
  end
end
