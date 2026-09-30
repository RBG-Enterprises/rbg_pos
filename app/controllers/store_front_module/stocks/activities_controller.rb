module StoreFrontModule
  module Stocks
    class ActivitiesController < ApplicationController
      include StockOverview

      def index
        @stock = current_store_front.stocks
          .includes(:product, purchase: { purchase_order: :supplier })
          .find(params[:stock_id])
        load_stock_overview
      end
    end
  end
end
