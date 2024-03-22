module Admin
  module Employees
    class ReportsController < AuthenticatedController
      def index
        @employee  = User.find(params[:employee_id])
        @from_date = params[:from_date] ? Time.zone.parse(params[:from_date]) : Date.current.beginning_of_month
        @to_date = params[:to_date] ? Time.zone.parse(params[:to_date]) : Date.current.end_of_month

      end
    end
  end
end
