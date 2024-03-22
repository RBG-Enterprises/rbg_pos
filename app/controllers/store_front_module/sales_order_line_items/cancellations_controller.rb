module StoreFrontModule
  module SalesOrderLineItems
    class CancellationsController < AuthenticatedController
      def create
        @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:sales_order_line_item_id])
        ::Orders::SalesOrders::SalesOrderLineItems::Cancellation.new(line_item: @line_item, employee: current_user).cancel!
        redirect_to store_front_module_sales_order_url(@line_item.sales_order), alert: 'Item deleted successfully.'
      end
    end
  end
end
