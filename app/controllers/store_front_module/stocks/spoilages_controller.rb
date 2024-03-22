# frozen_string_literal: true

module StoreFrontModule
    module Stocks
      class SpoilagesController < AuthenticatedController
        def index
          @stock = current_store_front.stocks.find(params[:stock_id])
          @pagy, @spoilages = pagy(@stock.spoilages.processed)
        end

        def new
          @stock = current_store_front.stocks.find(params[:stock_id])
          @spoilage = ::Stocks::Spoilages::CreateService.new
        end

        def create
          @stock = current_store_front.stocks.find(params[:stock_id])
          @spoilage = ::Stocks::Spoilages::CreateService.run(
              spoilage_params.merge!(
                  user: current_user,
                  store_front: current_store_front,
                  stock: @stock
              )
          )
          if @spoilage.valid?
              redirect_to store_front_module_stock_url(@stock), notice: 'Spoilage created successfully'
          else
              render :new
          end
        end

        private def spoilage_params
          params.require(:stocks_spoilages_create_service).permit(:quantity)
        end
      end
    end
  end
