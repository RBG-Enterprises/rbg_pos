module ComputerRepairSection
  class InsightsController < AuthenticatedController
    def index
      @store_front = params[:store_front_id] ? current_business.store_fronts.find(params[:store_front_id]) : current_store_front
      @work_orders = @store_front.work_orders
    end
  end
end
