module StoreFrontModule
  module Orders
    module StockTransferOrders
      class AdditionalLineItemsController < AuthenticatedController
        def new
          @stock_transfer_order = current_store_front.delivered_stock_transfer_orders.find(params[:stock_transfer_id])
          @additional_line_item = StoreFrontModule::LineItems::StockTransferOrderLineItemProcessing.new
          @additional_line_item_order_processing = StoreFrontModule::Orders::StockTransferOrders::AdditionalLineItemOrderProcessing.new
          if params[:search].present?
            @pagy, @stocks   = pagy(current_store_front.stocks.processed.includes(:product, :purchase => [:unit_of_measurement]).text_search(params[:search]))
            @pagy, @products = pagy(Product.text_search(params[:search]))
          end
        end

        def create
          @stock_transfer_order = current_store_front.delivered_stock_transfer_orders.find(params[:stock_transfer_id])
          @additional_line_item = StoreFrontModule::LineItems::StockTransferOrderLineItemProcessing.new(stock_transfer_line_item_params)
          if @additional_line_item.valid?
            @additional_line_item.process!
            redirect_to new_store_front_module_stock_transfer_additional_line_item_url(@stock_transfer_order), notice: 'Item added successfully.'
          else
            render :new
          end
        end

        def destroy
          @stock_transfer_order = current_store_front.delivered_stock_transfer_orders.find(params[:stock_transfer_id])
          @item = current_cart.purchase_order_line_items.find(params[:id])
          @item.destroy
          redirect_to new_store_front_module_stock_transfer_additional_line_item_url(@stock_transfer_order), alert: 'Item removed successfully.'
        end

        private
        def stock_transfer_line_item_params
          params.require(:store_front_module_line_items_stock_transfer_order_line_item_processing).
          permit(:quantity, :unit_of_measurement_id, :product_id, :bar_code, :cart_id, :stock_id, :selling_price)
        end
      end
    end
  end
end
