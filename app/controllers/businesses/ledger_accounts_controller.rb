module Businesses
  class LedgerAccountsController < AuthenticatedController
    def new
      @ledger_account = current_business.ledger_accounts.build
      if params[:search].present?
        @accounts = AccountingModule::Account.text_search(params[:search]).paginate(page: params[:page], per_page: 25)
      else
        @accounts = AccountingModule::Account.all.paginate(page: params[:page], per_page: 25)
      end
    end
    def create
      @ledger_account = current_business.ledger_accounts.create(ledger_account_params)
      if @ledger_account.valid?
        @ledger_account.save!
        redirect_to new_business_ledger_account_url(current_business), notice: 'added successfully'
      else
        render :new
      end
    end

    private
    def ledger_account_params
      params.require(:ledger_account).
      permit(:account_id)
    end
  end
end
