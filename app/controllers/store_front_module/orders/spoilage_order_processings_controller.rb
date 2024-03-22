module StoreFrontModule
  module Orders
    class SpoilageOrderProcessingsController < AuthenticatedController
      def create
        @order = StoreFrontModule::Orders::SpoilageOrderProcessing.new(order_params)
        if @order.valid?
          @order.process!
          redirect_to store_front_module_spoilages_url, notice: " Spoilage order saved successfully."
        else
          redirect_to new_store_front_module_spoilage_order_line_item_processing_path, alert: "Error"
        end
      end
      private
      def order_params
        params.require(:store_front_module_orders_spoilage_order_processing).
        permit(:date,
               :employee_id,
               :cart_id,
               :description,
               :reference_number)
      end
    end
  end
end

