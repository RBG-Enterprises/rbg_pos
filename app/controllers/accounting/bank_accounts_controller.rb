module Accounting
  class BankAccountsController < AuthenticatedController
    def new
      @bank_account = BankAccount.new
    end
    def create
      @bank_account = BankAccount.create(bank_account_params)
      if @bank_account.valid?
        @bank_account.save
        redirect_to accounting_bank_account_url(@bank_account), notice: "Bank Account saved successfully."
      else
        render :new
      end
    end
    def show
      @bank_account = BankAccount.find(params[:id])
      @entries = @bank_account.cash_in_bank_account.entries.order(entry_date: :desc).all.paginate(page: params[:page], per_page: 35)
    end
    private
    def bank_account_params
      params.require(:bank_account).permit(
        :account_number,
        :bank_name,
        :cash_in_bank_account_id,
        :date,
        :business_id)
    end
  end
end
