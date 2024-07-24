# frozen_string_literal: true

module StoreFrontModule
  module Stocks
    class SyncsController < ApplicationController
      def create
        @stock = current_store_front.stocks.find(params[:stock_id])
        @stock.update_available_quantity!
        @stock.update_availability!

        redirect_to store_front_module_stock_url(@stock), notice: "Stock synced successfully"
      end
    end
  end
end
