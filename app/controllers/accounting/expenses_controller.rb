module Accounting
  class ExpensesController < AuthenticatedController
    def new
      @entry = AccountingModule::ExpenseForm.new
    end
    def create
      @entry = AccountingModule::ExpenseForm.new(entry_params)
      if @entry.valid?
        @entry.save
        redirect_to accounting_index_url, notice: "Fund Transfer saved successfully."
      else
        render :new
      end
    end

    private
    def entry_params
      params.require(:accounting_module_expense_form).permit(:user_id, :entry_date, :reference_number, :description, :debit_account_id, :credit_account_id, :amount)
    end
  end
end
