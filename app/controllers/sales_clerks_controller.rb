class SalesClerksController < AuthenticatedController
  def index
    @employees = current_business.employees.sales_clerk
  end
  def show
    @employee = current_business.employees.find(params[:id])
  end
end
