class AddStartCompleteTemplatesToSections < ActiveRecord::Migration
  def change
    add_column :sections, :start_template, :text
    add_column :sections, :complete_template, :text
  end
end
