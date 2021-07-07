class AddModelAndManufacturerToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :manufacturer, :string
    add_column :claims, :model_number, :string

    add_column :products, :manufacturer, :string
    add_column :products, :model_number, :string
  end
end
