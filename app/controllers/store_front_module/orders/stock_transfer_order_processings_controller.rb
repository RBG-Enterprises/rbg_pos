module StoreFrontModule
  module Orders
    class StockTransferOrderProcessingsController < AuthenticatedController
      def create
        @stock_transfer_order = StoreFrontModule::Orders::StockTransferOrderProcessing.new(order_params)
        if @stock_transfer_order.process!

          redirect_to store_front_module_stock_transfers_url, notice: " Stock Transfer Order saved successfully."
        else
          redirect_to new_store_front_module_stock_transfer_order_line_item_processing_url, alert: "Error"
        end
      end
      private
      def order_params
        params.require(:store_front_module_orders_stock_transfer_order_processing).
        permit(
               :destination_store_front_id,
               :account_number,
               :registry_id,
               :date,
               :employee_id,
               :cart_id,
               :description,
               :reference_number)
      end

    end
  end
end
