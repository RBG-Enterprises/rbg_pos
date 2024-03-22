module StoreFrontModule
  module Orders
    class ReceivedStockTransfersController < AuthenticatedController
      def index
        @orders = StoreFrontModule::Orders::ReceivedStockTransferOrder.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
      def show
        @order = StoreFrontModule::Orders::ReceivedStockTransferOrder.find(params[:id])
      end
    end
  end
end
