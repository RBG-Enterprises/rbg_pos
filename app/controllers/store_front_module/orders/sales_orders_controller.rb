module StoreFrontModule
  module Orders
    class SalesOrdersController < AuthenticatedController
      def index
        if params[:search].present?
          @pagy, @orders = pagy(current_store_front.sales_orders.text_search_with_stocks(params[:search]))
        else
          @pagy, @orders = pagy(current_store_front.sales_orders.includes(:commercial_document, :store_front, :employee, :line_items, :cash_payment, :other_sales_line_items, :sales_order_line_items).order(created_at: :desc))
        end
      end

      def show
        @order = current_store_front.sales_orders.find(params[:id])
      end

      def destroy
        @order = current_store_front.sales_orders.find(params[:id])
        if params[:work_order_id].present?
          @work_order = WorkOrder.find(params[:work_order_id])
        end
        @order.destroy_entry!
        if @work_order.present?
          @work_order.destroy_entry_for(order: order)
        end
        cancel_sales_order
        if @work_order.present?
          redirect_to repair_services_section_work_order_url(@work_order), notice: "deleted successfully"
        else
          redirect_to store_front_module_sales_orders_url, alert: "Deleted successfully"
        end
      end

      private

      def cancel_sales_order
        ::StoreFronts::Orders::SalesOrders::Cancellation.new(sales_order: @order).cancel!
      end

    end
  end
end
