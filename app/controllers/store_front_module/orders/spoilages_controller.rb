module StoreFrontModule
  module Orders
    class SpoilagesController < AuthenticatedController
      def index
        @orders = StoreFrontModule::Orders::SpoilageOrder.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
      def show
        @order = StoreFrontModule::Orders::SpoilageOrder.find(params[:id])
      end
    end
  end
end
