module Accounting
  class FinancesController < AuthenticatedController
    def index
      @accounts = AccountingModule::Account.cash_on_hand_accounts.all
    end
  end
end
