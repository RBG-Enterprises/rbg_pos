module StoreFrontModule
  module Orders
    module StockTransferOrders
      class AdditionalLineItemOrderProcessingsController < AuthenticatedController
        def create
          @stock_transfer_order = current_store_front.delivered_stock_transfer_orders.find(params[:stock_transfer_id])
          @additional_line_item_order_processing = StoreFrontModule::Orders::StockTransferOrders::AdditionalLineItemOrderProcessing.new(order_params)
          @additional_line_item_order_processing.process!
          redirect_to store_front_module_stock_transfer_url(@stock_transfer_order), notice: 'Items added successfully'
        end

        private
        def order_params
          params.require(:store_front_module_orders_stock_transfer_orders_additional_line_item_order_processing).
          permit(:cart_id, :stock_transfer_order_id)
        end
      end
    end
  end
end
