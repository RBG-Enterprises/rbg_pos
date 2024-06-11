class AddDestinationStoreFrontToLineItems < ActiveRecord::Migration[6.1]
  def change
    add_reference :line_items, :destination_store_front, null: true, foreign_key: { to_table: :store_fronts }
  end
end
