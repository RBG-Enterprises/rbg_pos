module StoreFrontModule
  module Stocks
    class ActivitiesController < ApplicationController
      def index
        @stock = current_store_front.stocks.find(params[:stock_id])
      end
    end
  end
end
