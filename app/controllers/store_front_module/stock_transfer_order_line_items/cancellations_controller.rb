module StoreFrontModule
  module StockTransferOrderLineItems
    class CancellationsController < ApplicationController
      def create
        @line_item = StoreFrontModule::LineItems::StockTransferOrderLineItem.find(params[:stock_transfer_order_line_item_id])
        ::LineItems::StockTransferOrderLineItems::Cancellation.run(line_item: @line_item)
        redirect_to store_front_module_stock_transfer_url(@line_item.order), alert: 'Item deleted successfully.'
      end
    end
  end
end
