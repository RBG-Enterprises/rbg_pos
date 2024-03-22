module StoreFrontModule
  module StockTransferOrderLineItems
    class CancellationsController < AuthenticatedController
      def create
        @line_item = StoreFrontModule::LineItems::PurchaseOrderLineItem.find(params[:stock_transfer_order_line_item_id])
        ::LineItems::StockTransferOrderLineItems::Cancellation.new(line_item: @line_item).cancel!
        redirect_to store_front_module_stock_transfer_url(@line_item.order), alert: 'Item deleted successfully.'
      end
    end
  end
end
