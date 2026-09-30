module StoreFrontModule
  module Stocks
    class StockTransfersController < ApplicationController
      include StockOverview

      def index
        @stock = current_store_front.stocks
          .includes(:product, purchase: { purchase_order: :supplier })
          .find(params[:stock_id])
        @pagy, @stock_transfers = pagy(@stock.stock_transfers.processed.includes(:purchase_order).order(created_at: :desc))
        load_stock_overview
      end
    end
  end
end
