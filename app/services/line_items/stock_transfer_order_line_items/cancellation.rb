
# frozen_string_literal: true
class LineItems::StockTransferOrderLineItems::Cancellation < ActiveInteraction::Base
  object :line_item

  def execute
    ActiveRecord::Base.transaction do
      line_item.stock.destroy
      line_item.destroy
    end
  end
end
