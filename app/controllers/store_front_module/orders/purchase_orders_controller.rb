module StoreFrontModule
  module Orders
    class PurchaseOrdersController < AuthenticatedController
      def index
         if params[:search].present?
          @pagy, @orders = pagy(current_store_front.purchase_orders.not_stock_transfers.text_search_with_stocks(params[:search]).order(created_at: :desc))
        else
          @pagy, @orders = pagy(current_store_front.purchase_orders.not_stock_transfers.order(created_at: :desc))
        end
      end

      def show
        @order = current_store_front.purchase_orders.not_stock_transfers.find(params[:id])
        @pagy, @line_items = pagy(@order.purchase_order_line_items.order(created_at: :asc))
      end
    end
  end
end
