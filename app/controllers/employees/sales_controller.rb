module Employees
  class SalesController < AuthenticatedController
    def index
      @employee = User.find(params[:employee_id])
      @orders = @employee.sales_orders.order(date: :desc).all.paginate(page: params[:page], per_page: 35)
    end
  end
end
