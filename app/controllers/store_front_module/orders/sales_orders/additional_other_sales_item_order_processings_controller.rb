module StoreFrontModule
  module Orders
    module SalesOrders
      class AdditionalOtherSalesItemOrderProcessingsController < AuthenticatedController
        def create
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @additional_other_sales_order = StoreFrontModule::Orders::OtherSalesLineItemOrderProcessing.new(other_item_params)
          @additional_other_sales_order.process!
          redirect_to store_front_module_sales_order_url(@sales_order), notice: "Other items added successfully."
        end

        private
        def other_item_params
          params.require(:store_front_module_orders_other_sales_line_item_order_processing).
          permit(:date, :cart_id, :sales_order_id, :recorder_id)
        end
      end
    end
  end
end
