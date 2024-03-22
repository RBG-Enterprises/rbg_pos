module StoreFrontModule
  module Orders
    class PurchaseReturnsController < AuthenticatedController
      def index
        @purchase_returns = StoreFrontModule::Orders::PurchaseReturnOrder.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
      def show
        @order = StoreFrontModule::Orders::PurchaseReturnOrder.find(params[:id])
      end
    end
  end
end
