class AddFieldsToBenefitProgramsAndCategories < ActiveRecord::Migration
  def change
    add_column :benefit_programs, :start_date, :date
    add_column :benefit_programs, :end_date, :date
  end
end
