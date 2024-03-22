module Admin
  module Employees
    class EntriesController < AuthenticatedController
      def index
        @employee = User.find(params[:employee_id])
        @entries = @employee.entries.order(entry_date: :desc).all.paginate(page: params[:page], per_page: 35)
      end
    end
  end
end
