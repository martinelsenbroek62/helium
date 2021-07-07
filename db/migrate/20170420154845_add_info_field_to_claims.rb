class AddInfoFieldToClaims < ActiveRecord::Migration
  def change
    add_column :claims, :more_info, :text
  end
end
