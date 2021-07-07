class AddTrashBooleansToModels < ActiveRecord::Migration
  def change
    add_column :sections, :trash, :boolean, default:false
    add_column :groups, :trash, :boolean, default:false
    add_column :questions, :trash, :boolean, default:false
  end
end
