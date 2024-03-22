module StoreFrontModule
  module Orders
    class InternalUseOrdersController < AuthenticatedController
      def index
        @orders = StoreFrontModule::Orders::InternalUseOrder.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
      def show
        @order =StoreFrontModule::Orders::InternalUseOrder.find(params[:id])
      end
    end
  end
end
