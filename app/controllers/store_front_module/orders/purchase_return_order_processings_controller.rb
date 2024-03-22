module StoreFrontModule
  module Orders
    class PurchaseReturnOrderProcessingsController < AuthenticatedController
      def create
        @purchase_return_order = StoreFrontModule::Orders::PurchaseReturnOrderProcessing.new(order_params)
        if @purchase_return_order.valid?
          @purchase_return_order.process!
          redirect_to store_front_module_purchase_returns_url, notice: "Purchase Return Order saved successfully"
        else
          redirect_to new_store_front_module_purchase_return_order_line_item_processing_url, alert: "Error"
        end
      end

      private
      def order_params
        params.require(:store_front_module_orders_purchase_return_order_processing).
        permit(:date, :supplier_id, :description, :cart_id, :employee_id, :account_number)
      end
    end
  end
end
