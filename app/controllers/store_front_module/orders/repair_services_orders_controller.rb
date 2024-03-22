module StoreFrontModule
  module Orders
    class RepairServicesOrdersController < AuthenticatedController
      def index
        @orders = RepairServicesModule::RepairServiceOrder.all.paginate(page: params[:page], per_page: 30)
      end
      def show
        @order = RepairServicesModule::RepairServiceOrder.find(params[:id])
      end
    end
  end
end
