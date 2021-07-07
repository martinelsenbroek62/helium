class AddImageUrlToBenefitPrograms < ActiveRecord::Migration
  def change
    add_column :benefit_programs, :image, :string
  end
end
