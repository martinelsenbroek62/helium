class AddBenefitAssociationToFunds < ActiveRecord::Migration
  def change
    add_column :funds, :benefit_program_id, :integer
    add_column :funds, :benefit_category_id, :integer
  end
end
