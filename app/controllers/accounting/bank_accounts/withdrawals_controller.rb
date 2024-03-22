module Accounting
  module BankAccounts
    class WithdrawalsController < AuthenticatedController
      def new
        @bank_account = BankAccount.find(params[:bank_account_id])
        @withdrawal = Accounting::BankAccounts::Withdrawal.new
      end
      def create
        @bank_account = BankAccount.find(params[:bank_account_id])
        @withdrawal = Accounting::BankAccounts::Withdrawal.new(deposit_params)
        if @withdrawal.valid?
          @withdrawal.save!
          redirect_to accounting_bank_account_url(@bank_account), notice: "Withdrawal saved successfully"
        else
          render :new
        end
      end

      private
      def deposit_params
        params.require(:accounting_bank_accounts_withdrawal).permit(:bank_account_id, :destination_account_id, :amount, :date, :reference_number, :description, :employee_id)
      end
    end
  end
end
