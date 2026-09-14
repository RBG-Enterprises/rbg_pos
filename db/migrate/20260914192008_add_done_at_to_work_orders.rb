class AddDoneAtToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :work_orders, :done_at, :datetime
  end
end
