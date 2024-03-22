module StoreFrontModule
  class StocksController < AuthenticatedController
    def show
      @stock = current_store_front.stocks.find(params[:id])
    end
  end
end
