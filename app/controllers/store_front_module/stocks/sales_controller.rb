module StoreFrontModule
  module Stocks
    class SalesController < ApplicationController
      include StockOverview

      def index
        @stock = current_store_front.stocks
          .includes(:product, purchase: { purchase_order: :supplier })
          .find(params[:stock_id])
        @pagy, @sales = pagy(@stock.sales.processed.includes(:order, sales_order: :commercial_document).order(created_at: :desc))
        load_stock_overview
      end
    end
  end
end
