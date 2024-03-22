module Accounting
  module BankAccounts
    class DepositsController < AuthenticatedController
      def new
        @bank_account = BankAccount.find(params[:bank_account_id])
        @deposit = Accounting::BankAccounts::Deposit.new
      end
      def create
        @bank_account = BankAccount.find(params[:bank_account_id])
        @deposit = Accounting::BankAccounts::Deposit.new(deposit_params)
        if @deposit.valid?
          @deposit.save!
          redirect_to accounting_bank_account_url(@bank_account), notice: "Deposit saved successfully"
        else
          render :new
        end
      end

      private
      def deposit_params
        params.require(:accounting_bank_accounts_deposit).permit(:bank_account_id, :source_account_id, :amount, :date, :reference_number, :description, :employee_id)
      end
    end
  end
end
