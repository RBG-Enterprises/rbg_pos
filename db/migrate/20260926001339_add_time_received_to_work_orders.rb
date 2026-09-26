class AddTimeReceivedToWorkOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :work_orders, :time_received, :datetime
  end
end
