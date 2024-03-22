require 'will_paginate/array'
module RepairServicesModule
  class ServicePaymentsController < AuthenticatedController
    def index
      @service_payments = WorkOrder.payment_entries.sort_by(&:entry_date).reverse.paginate(page: params[:page], per_page: 35)
    end
    def show
      @payment = AccountingModule::Entry.find(params[:id])
    end
  end
end
