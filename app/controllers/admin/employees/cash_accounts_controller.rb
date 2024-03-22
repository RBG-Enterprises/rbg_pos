module Admin
  module Employees
    class CashAccountsController < AuthenticatedController
      def new
        @employee     = current_store_front.employees.find(params[:employee_id])
        @cash_account = @employee.employee_cash_accounts.build
      end

      def create
        @employee     = current_store_front.employees.find(params[:employee_id])
        @cash_account = @employee.employee_cash_accounts.create(cash_account_params)
        if @cash_account.valid?
          @cash_account.save!
          redirect_to admin_employee_settings_path(@employee), notice: 'Cash account saved successfully'
        else
          render :new
        end
      end

      private
      def cash_account_params
        params.require(:employees_employee_cash_account).
        permit(:cash_account_id)
      end
    end
  end
end
