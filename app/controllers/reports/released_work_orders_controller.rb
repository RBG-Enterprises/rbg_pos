module Reports
  class ReleasedWorkOrdersController < AuthenticatedController
    def index
      @employee = User.find(params[:user_id])
      @from_date = params[:from_date] ? Time.zone.parse(params[:from_date]) : Date.current.beginning_of_month
      @to_date   = params[:to_date] ? Time.zone.parse(params[:to_date]) : Date.current.beginning_of_month

      @work_orders = @employee.work_orders.released_on(from_date: @from_date, to_date: @to_date)
      respond_to do |format|
        format.xlsx
      end
    end
  end
end
