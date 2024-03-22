module StoreFrontModule
  module LineItems
    class ReceivedStockTransferOrderLineItemProcessingsController <  AuthenticatedController
      def new
        if params[:search].present?
          @products = Product.text_search(params[:search]).all
          @line_items = StoreFrontModule::LineItems::ReceivedStockTransferOrderLineItem.processed.text_search(params[:search])
        end
        @cart = current_cart
        @received_stock_transfer_order_line_item = StoreFrontModule::LineItems::ReceivedStockTransferOrderLineItemProcessing.new
        @received_stock_transfer_order = StoreFrontModule::Orders::ReceivedStockTransferOrderProcessing.new
        @received_stock_transfer_order_line_items = @cart.received_stock_transfer_order_line_items.order(created_at: :desc)
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::PurchaseOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to store_front_module_received_stock_transfer_registry_url(@line_item.registry), notice: "deleted successfully"
      end
    end
  end
end
