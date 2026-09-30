module StoreFrontModule
  module Stocks
    class InternalUsesController < ApplicationController
      include StockOverview

      def index
        @stock = current_store_front.stocks
          .includes(:product, purchase: { purchase_order: :supplier })
          .find(params[:stock_id])
        @pagy, @internal_uses = pagy(@stock.internal_uses.processed.includes(:internal_use_order).order(created_at: :desc))
        load_stock_overview
      end
    end
  end
end
