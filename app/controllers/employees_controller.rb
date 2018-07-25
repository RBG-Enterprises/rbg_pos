class EmployeesController < ApplicationController
  def index
    @employees = User.all
  end
  def show
    @employee = User.find(params[:id])
    @orders = @employee.orders.paginate(page: params[:page], per_page: 35)
    @entries = @employee.entries.order(entry_date: :desc).paginate(page: params[:page], per_page: 35)
    authorize @employee
  end
end
