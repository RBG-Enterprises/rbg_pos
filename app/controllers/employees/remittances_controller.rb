module Employees
  class RemittancesController < AuthenticatedController
    def new
      @employee = User.find(params[:employee_id])
      @entry = AccountingModule::RemittanceForm.new
      @cash_account = AccountingModule::Account.find(params[:cash_account_id])
    end
    def create
      @employee = User.find(params[:employee_id])
      @entry = AccountingModule::RemittanceForm.new(entry_params)
      if @entry.valid?
        @entry.save
        redirect_to admin_employee_url(@employee), notice: "Collection remittance saved successfully."
      else
        render :new
      end
    end

    private
    def entry_params
      params.require(:accounting_module_remittance_form).permit(:recorder_id,:cashier_id, :entry_date, :reference_number, :description, :debit_account_id, :credit_account_id, :amount)
    end
  end
end
