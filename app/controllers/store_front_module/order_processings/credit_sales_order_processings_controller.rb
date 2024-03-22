module StoreFrontModule
  module OrderProcessings
    class CreditSalesOrderProcessingsController < AuthenticatedController
      def create
        @customer = Customer.find(params[:customer_id])
         @sales_order = StoreFrontModule::Orders::CreditSalesOrderProcessing.new(order_params)
        if @sales_order.valid?
          @sales_order.process!
          redirect_to customer_url(@customer), notice: "Credit Order saved successfully."
        else
          redirect_to new_store_front_module_customer_credit_sales_order_line_item_processing_url(@customer), alert: "Error"
        end
      end

      private
      def order_params
        params.require(:store_front_module_orders_credit_sales_order_processing).
        permit(:customer_id,
               :department_id,
               :date,
               :employee_id,
               :cart_id,
               :description,
               :store_front_id,
               :account_number,
               :reference_number)
      end
    end
  end
end
