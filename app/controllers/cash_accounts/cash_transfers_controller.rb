module CashAccounts
  class CashTransfersController < AuthenticatedController
    def new
      @cash_account = AccountingModule::Asset.find(params[:cash_account_id])
      @cash_transfer = AccountingModule::CashTransferVoucher.new
    end
    def create
      @cash_account = AccountingModule::Asset.find(params[:cash_account_id])
      @cash_transfer = AccountingModule::CashTransferVoucher.new(cash_transfer_voucher_params)
      if @cash_transfer.valid?
        @cash_transfer.process!
        redirect_to voucher_url(@cash_transfer.find_voucher), notice: "Cash Transfer voucher created successfully."
      else
        render :new
      end
    end

    private
    def cash_transfer_voucher_params
      params.require(:accounting_module_cash_transfer_voucher).
      permit(:employee_id, :entry_date, :reference_number, :description, :amount, :debit_account_id, :credit_account_id, :account_number)
    end
  end
end
