module Reports
  class WorkOrdersController < AuthenticatedController
    def index
      @work_orders = WorkOrder.all.to_a.sort_by(&:elapsed_time)
      respond_to do |format|
        format.xlsx
      end
    end
  end
end
