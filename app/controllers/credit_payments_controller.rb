require 'will_paginate/array'
class CreditPaymentsController < AuthenticatedController
  def index
    @credit_payments = StoreFrontModule::StoreFrontConfig.default_accounts_receivable_account.credit_amounts.where.not(commercial_document_type: "WorkOrder").sort_by(&:entry_date).reverse.paginate(page: params[:page], per_page: 25)
  end
end
