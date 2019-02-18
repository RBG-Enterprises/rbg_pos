module Employees
  class BankRemittancesController < ApplicationController
    def new
      @employee = User.find(params[:employee_id])
      @cash_account = AccountingModule::Account.find(params[:cash_account_id])
    end
  end
end 
