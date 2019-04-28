module Employees
  class CashCountsController < ApplicationController
    def new
      @employee = User.find(params[:employee_id])
      @cash_count = @employee.cash_counts.new
      @bill_count = Employees::BillCount.new
    end
  end
end
