module StoreFrontModule
  module StoreFronts
    class ReportsController < AuthenticatedController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
      end
    end
  end
end
