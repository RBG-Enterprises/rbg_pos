module StoreFrontModule
  module Stocks
    class SalesController < ApplicationController
      def index
        @stock = current_store_front.stocks.find(params[:stock_id])
        @pagy, @sales = pagy(@stock.sales.processed)
      end
    end
  end
end
