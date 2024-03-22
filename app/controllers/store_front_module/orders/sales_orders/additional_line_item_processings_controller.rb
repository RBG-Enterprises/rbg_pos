module StoreFrontModule
  module Orders
    module SalesOrders
      class AdditionalLineItemProcessingsController < AuthenticatedController
        def create
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @cart = Cart.find(params[:store_front_module_line_items_additional_sales_order_line_item_processing][:cart_id])
          StoreFrontModule::LineItems::AdditionalSalesOrderLineItemProcessing.new(date: params[:store_front_module_line_items_additional_sales_order_line_item_processing][:date], sales_order: @sales_order, cart: @cart, employee: current_user).process!
          redirect_to store_front_module_sales_order_path(@sales_order), notice: "Additional line items saved successfully."
        end
      end
    end
  end
end
