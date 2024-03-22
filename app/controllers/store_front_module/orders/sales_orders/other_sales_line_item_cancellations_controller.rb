module StoreFrontModule
  module Orders
    module SalesOrders
      class OtherSalesLineItemCancellationsController < AuthenticatedController
        def destroy
          @sales_order = current_store_front.sales_orders.find(params[:sales_order_id])
          @other_sales_line_item = @sales_order.other_sales_line_items.find(params[:other_sales_line_item_id])
          ::Orders::SalesOrders::OtherSalesLineItems::Cancellation.new(other_sales_line_item: @other_sales_line_item, employee: current_user).cancel!
          redirect_to store_front_module_sales_order_url(@sales_order), notice: 'Item cancelled successfully'
        end
      end
    end
  end
end
