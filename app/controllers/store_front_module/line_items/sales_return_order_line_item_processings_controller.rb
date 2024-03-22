module StoreFrontModule
  module LineItems
    class SalesReturnOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @pagy, @sales_orders = pagy(current_store_front.sales_orders.text_search_with_stocks(params[:search]))
        end
      end
    end
  end
end
