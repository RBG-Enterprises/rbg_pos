module Admin
  module Employees
    class SettingsController < AuthenticatedController
      def index
        @employee = current_store_front.employees.find(params[:employee_id])
      end
    end
  end
end
