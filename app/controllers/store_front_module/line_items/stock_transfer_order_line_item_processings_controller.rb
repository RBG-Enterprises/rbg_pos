module StoreFrontModule
  module LineItems
    class StockTransferOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @pagy, @products   = pagy(Product.text_search(params[:search]))
          @pagy, @stocks     = pagy(current_store_front.stocks.processed.barcode_search(params[:search]))

        end
        @cart = current_cart
        @stock_transfer_order_line_item = StoreFrontModule::LineItems::StockTransferOrderLineItemProcessing.new
        @stock_transfer_order = StoreFrontModule::Orders::StockTransferOrderProcessing.new
        @purchase_order_line_items = @cart.purchase_order_line_items.order(created_at: :desc)
      end

      def create
        @line_item = StoreFrontModule::LineItems::StockTransferOrderLineItemProcessing.new(line_item_params)
        if @line_item.process!
          @line_item.find_stock.update_availability_for_cart(current_cart)

          redirect_to new_store_front_module_stock_transfer_order_line_item_processing_url, notice: "added to cart"
        else
          render :new, alert: "Error"
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::PurchaseOrderLineItem.find(params[:id])
        @line_item.destroy
        ::StockTransferCancellation.new(line_item: @line_item, cart: current_cart).cancel_transfer!
        @line_item.stock.update_availability_for_cart(current_cart)

        redirect_to new_store_front_module_stock_transfer_order_line_item_processing_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_stock_transfer_order_line_item_processing).
        permit(:quantity, :unit_of_measurement_id, :product_id, :bar_code, :cart_id, :stock_id, :selling_price)
      end
    end
  end
end
