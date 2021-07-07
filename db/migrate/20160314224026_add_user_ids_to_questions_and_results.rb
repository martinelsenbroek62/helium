class AddUserIdsToQuestionsAndResults < ActiveRecord::Migration
  def change
    add_column :questions, :user_id, :integer
    add_column :results, :user_id, :integer

    add_index :questions, :user_id
    add_index :results, :user_id
  end
end
