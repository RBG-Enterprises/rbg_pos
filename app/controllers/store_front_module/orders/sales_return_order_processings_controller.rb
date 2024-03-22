module StoreFrontModule
  module Orders
    class SalesReturnOrderProcessingsController < AuthenticatedController
      def create
        @sales_return_order = StoreFrontModule::Orders::SalesReturnOrderProcessing.new(order_params)
        if @sales_return_order.valid?
          @sales_return_order.process!
          redirect_to store_front_module_sales_returns_url, notice: " Sales return saved successfully."
        else
          redirect_to new_store_front_module_sales_return_order_line_item_processing_path, alert: "Error"
        end
      end
      private
      def order_params
        params.require(:store_front_module_orders_sales_return_order_processing).
        permit(:customer_id,
               :date,
               :employee_id,
               :cart_id,
               :description,
               :reference_number)
      end
    end
  end
end

