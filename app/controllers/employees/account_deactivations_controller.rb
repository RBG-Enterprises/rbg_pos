module Employees
    class AccountDeactivationsController < AuthenticatedController
      def create
        @employee = User.find(params[:employee_id])
        @employee.update!(deactivated_at: Time.zone.now)
        redirect_to employee_url(@employee), notice: 'Account deactivated successfully.'
        @cash_count = @employee.cash_counts.new
        @bill_count = Employees::BillCount.new
      end
    end
  end
