class AddDeactivatedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :deactivated_at, :datetime
    add_index :users, :deactivated_at
  end
end
