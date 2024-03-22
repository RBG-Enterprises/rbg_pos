module StoreFrontModule
  module Orders
    class InternalUseOrderProcessingsController < AuthenticatedController
      def create
        @order = StoreFrontModule::Orders::InternalUseOrderProcessing.new(order_params)
        if @order.valid?
          @order.process!
          redirect_to store_front_module_internal_use_orders_url, notice: "Purchase Order saved successfully"
        else
          redirect_to new_store_front_module_internal_use_order_line_item_processing_url, alert: "Error"
        end
      end

      private
      def order_params
        params.require(:store_front_module_orders_internal_use_order_processing).
        permit(:date, :description, :cart_id, :commercial_document_id, :employee_id)
      end
    end
  end
end
