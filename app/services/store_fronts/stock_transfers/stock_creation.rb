# frozen:string_literal: true
class StoreFronts::StockTransfers::StockCreation
  attr_reader :line_item, :stock, :destination_store_front

  def initialize(line_item:, destination_store_front:)
    @line_item               = line_item
    @destination_store_front = destination_store_front
    @stock                   = @line_item.stock
  end

  def create_stock!
    new_stock = StoreFronts::Stock.create!(
    store_front: destination_store_front,
    available:           true,
    product:             line_item.product,
    unit_of_measurement: line_item.unit_of_measurement,
    available_quantity:  line_item.quantity,
    is_processed:        true,
    barcode:             stock.barcode)

    line_item.update!(stock: new_stock)
  end
end
