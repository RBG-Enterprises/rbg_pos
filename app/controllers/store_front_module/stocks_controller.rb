module StoreFrontModule
  class StocksController < ApplicationController
    include StockOverview

    def show
      @stock = current_store_front.stocks
        .includes(:product, :unit_of_measurement, purchase: { purchase_order: :supplier })
        .find(params[:id])
      load_stock_overview
    end
  end
end 
