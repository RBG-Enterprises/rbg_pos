module ComputerRepairSection 
  class DashboardController < ApplicationController
    def index 
      @from_date = params[:from_date] || Time.zone.now.beginning_of_week
      @to_date = params[:to_date] || Time.zone.now.end_of_week
      if params[:technician].present?
        @technician = User.find(params[:technician])
        @work_orders = @technician.work_orders.page(params[:page]).per(20)
      elsif params[:search].present?
        @work_orders = WorkOrder.text_search(params[:search]).page(params[:page]).per(20)
      else
        @work_orders = WorkOrder.from(from_date: @from_date, to_date: @to_date).page(params[:page]).per(20)
      end
    end 
  end 
end 