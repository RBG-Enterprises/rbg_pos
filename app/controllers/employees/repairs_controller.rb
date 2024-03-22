module Employees
  class RepairsController < AuthenticatedController
    def index
      @employee = User.find(params[:employee_id])
      @work_orders = @employee.work_orders.paginate(page: params[:page], per_page: 25)
    end
  end
end
