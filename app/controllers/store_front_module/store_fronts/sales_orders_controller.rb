module StoreFrontModule
  module StoreFronts
    class SalesOrdersController < AuthenticatedController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        if params[:from_date] && params[:to_date]
          @from_date = Date.parse(params[:from_date])
          @to_date   = Date.parse(params[:to_date])
          @all_sales_orders = @store_front.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
          @pagy, @sales_orders = pagy(@store_front.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date))
        else
          @pagy, @sales_orders = pagy(@store_front.sales_orders)
          @all_sales_orders = @store_front.sales_orders
        end
      end
    end
  end
end
