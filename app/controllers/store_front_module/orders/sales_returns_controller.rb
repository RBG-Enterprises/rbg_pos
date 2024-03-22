module StoreFrontModule
  module Orders
    class SalesReturnsController < AuthenticatedController
      def index
        @orders = StoreFrontModule::Orders::SalesReturnOrder.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
      def show
        @order = StoreFrontModule::Orders::SalesReturnOrder.find(params[:id])
      end
    end
  end
end
