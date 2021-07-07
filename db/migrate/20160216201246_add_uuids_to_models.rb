class AddUuidsToModels < ActiveRecord::Migration
  def change
    add_column :groups, :uuid, :string
    add_column :organizations, :uuid, :string
    add_column :questions, :uuid, :string
    add_column :rules, :uuid, :string
    add_column :sections, :uuid, :string
    add_column :surveys, :uuid, :string
    add_column :users, :uuid, :string

    add_index :groups, :uuid
    add_index :organizations, :uuid
    add_index :questions, :uuid
    add_index :rules, :uuid
    add_index :sections, :uuid
    add_index :surveys, :uuid
    add_index :users, :uuid
  end
end
