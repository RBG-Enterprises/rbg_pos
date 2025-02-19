class AddReturnedAtToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :returned_at, :datetime
  end
end
