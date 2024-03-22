module Employees
  class ReportsController < AuthenticatedController
    def index
      @employee = User.find(params[:employee_id])
    end
  end
end
