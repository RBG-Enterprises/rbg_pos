module Employees
  class CashOnHandAccountsController < AuthenticatedController
    def show
      @account  = AccountingModule::Account.find(params[:id])
      @employee = User.find(params[:employee_id])
      @to_date  = params[:to_date] ? Date.parse(params[:to_date]) : Date.yesterday.end_of_day
    end
  end
end
