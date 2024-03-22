module StoreFrontModule
  module Stocks
    class InternalUsesController < AuthenticatedController
      def index
        @stock = current_store_front.stocks.find(params[:stock_id])
        @pagy, @internal_uses = pagy(@stock.internal_uses.processed)
      end
    end
  end
end
