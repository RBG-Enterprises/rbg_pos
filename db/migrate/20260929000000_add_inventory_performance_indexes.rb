# frozen_string_literal: true

# Speeds up GET /inventories on large datasets (395k+ stocks):
# - stocks(store_front_id, is_processed): pagy COUNT + page query filter.
# - line_items(stock_id, type, order_id): the `processed` join
#   (joins(:purchase)) and per-stock processed balance lookups filter on
#   all three columns.
class AddInventoryPerformanceIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :stocks, [:store_front_id, :is_processed],
      name: "index_stocks_on_store_front_and_processed"
    add_index :line_items, [:stock_id, :type, :order_id],
      name: "index_line_items_on_stock_type_and_order"
  end
end
