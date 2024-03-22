module Insights
  class ReceivablesController < AuthenticatedController
    def index
      @accounts_receivable = AccountingModule::AccountCategories::Asset.find_by(title: "Accounts Receivable")
    end
  end
end
