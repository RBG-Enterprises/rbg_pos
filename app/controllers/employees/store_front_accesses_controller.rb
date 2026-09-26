module Employees
  class StoreFrontAccessesController < ApplicationController
    def create
      @employee = User.find(params[:employee_id])
      authorize @employee, :update?
      store_front = assignable_store_fronts.find_by(id: store_front_access_params[:store_front_id])
      if store_front
        @employee.user_store_fronts.find_or_create_by!(store_front: store_front)
        redirect_to employee_settings_path(@employee), notice: "#{store_front.name} added to #{@employee.full_name}'s store fronts."
      else
        redirect_to employee_settings_path(@employee), alert: "Store front not found."
      end
    end

    def destroy
      @employee = User.find(params[:employee_id])
      authorize @employee, :update?
      access = @employee.user_store_fronts.find(params[:id])
      access.destroy
      redirect_to employee_settings_path(@employee), notice: "#{access.store_front.name} removed from #{@employee.full_name}'s store fronts."
    end

    private

    def store_front_access_params
      params.require(:store_front_access).permit(:store_front_id)
    end

    def assignable_store_fronts
      business = @employee.business || current_business
      business ? business.store_fronts : StoreFront.all
    end
  end
end
