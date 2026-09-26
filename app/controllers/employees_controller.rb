class EmployeesController < ApplicationController
  def index
    @employees = User.includes(:store_front).with_attached_avatar
    @employees = @employees.text_search(params[:search]) if params[:search].present?
    @employees = @employees.paginate(page: params[:page], per_page: 35)
  end
  def show
    @employee = User.find(params[:id])
    @orders = @employee.orders.paginate(page: params[:page], per_page: 35)
    @entries = @employee.entries.order(entry_date: :desc).paginate(page: params[:page], per_page: 35)
    authorize @employee
  end
  def update
    @employee = User.find(params[:id])
    authorize @employee, :update_avatar?
    if @employee.update(employee_params)
      redirect_to employee_settings_path(@employee), notice: "Employee photo updated successfully."
    else
      redirect_to employee_settings_path(@employee), alert: "Failed to update employee photo."
    end
  end

  private

  def employee_params
    params.require(:user).permit(:avatar)
  end
end
