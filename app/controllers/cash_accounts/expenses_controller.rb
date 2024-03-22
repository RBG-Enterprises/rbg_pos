module CashAccounts
  class ExpensesController < AuthenticatedController
    def new
      @cash_account = AccountingModule::Asset.find(params[:cash_account_id])
      @expense      = CashAccounts::ExpenseVoucher.new
    end
    def create
      @cash_account = AccountingModule::Asset.find(params[:cash_account_id])
      @expense      = CashAccounts::ExpenseVoucher.new(expense_params)
      if @expense.valid?
        @expense.process!
        redirect_to voucher_url(@expense.find_voucher), notice: 'created successfully'
      else
        render :new
      end
    end

    private
    def expense_params
      params.require(:cash_accounts_expense_voucher).
      permit(:date, :reference_number, :description, :account_number, :debit_account_id, :credit_account_id, :amount, :employee_id)
    end
  end
end
