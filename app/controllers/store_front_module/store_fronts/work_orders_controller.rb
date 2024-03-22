module StoreFrontModule
  module StoreFronts
    class WorkOrdersController < AuthenticatedController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @service_receiveable_account_category = @store_front.service_receivable_account_category
        @all_work_orders = @store_front.work_orders
        @pagy, @work_orders = pagy(@store_front.work_orders)
        respond_to do |format|
          format.html
          format.xlsx
        end
      end
    end
  end
end
