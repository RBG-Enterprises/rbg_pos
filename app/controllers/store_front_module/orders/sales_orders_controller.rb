module StoreFrontModule
  module Orders
    class SalesOrdersController < ApplicationController
      def index
        if params[:search].present?
          @pagy, @orders = pagy(StoreFrontModule::Orders::SalesOrder.for_store_front(current_store_front).text_search(params[:search]))
        else
          @pagy, @orders = pagy(StoreFrontModule::Orders::SalesOrder.for_store_front(current_store_front).order(date: :desc))
        end
        @sales_for_today = StoreFrontModule::Orders::SalesOrder.ordered_on(from_date: Date.today, to_date: Date.today)
      end
      def show
        @order = StoreFrontModule::Orders::SalesOrder.find(params[:id])
      end
      def destroy
        @order = StoreFrontModule::Orders::SalesOrder.find(params[:id])
        if params[:work_order_id].present?
          @work_order = WorkOrder.find(params[:work_order_id])
        end
        @order.destroy_entry!
        if @work_order.present?
          @work_order.destroy_entry_for(order: order)
        end
        @order.destroy
        if @work_order.present?
          redirect_to repair_services_section_work_order_url(@work_order), notice: "deleted successfully"
        else
          redirect_to store_front_module_sales_orders_url, alert: "Deleted successfully"
        end
      end
    end
  end
end
