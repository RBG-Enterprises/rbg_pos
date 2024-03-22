module Admin
  class EmployeesController < AuthenticatedController
    def show
      @employee = User.find(params[:id])
      @cash_account = @employee.cash_on_hand_account
      @to_date    = params[:to_date] ? Date.parse(params[:to_date]) : Date.current.end_of_day
    end
  end
end
