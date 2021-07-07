class AddIntroTextToGroups < ActiveRecord::Migration
  def up
    change_column :groups, :intro, :text
  end

  def down
    change_column :groups, :intro, :string
  end
end
