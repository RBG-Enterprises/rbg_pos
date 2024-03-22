class CashAccountsController < AuthenticatedController
  def show
    @cash_account = AccountingModule::Asset.find(params[:id])
    if params[:from_date] && params[:to_date]
      @pagy, @entries = pagy(@cash_account.entries.order(entry_date: :desc).entered_on(from_date: params[:from_date], to_date: params[:to_date]).distinct)
    else
      @pagy, @entries = pagy(@cash_account.entries.order(entry_date: :desc).distinct)
    end
  end
end
