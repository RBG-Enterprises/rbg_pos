# frozen_string_literal: true

require "will_paginate/array"
module RepairServicesModule
  class ServicePaymentsController < ApplicationController
    def index
      @service_payments = WorkOrder.payment_entries.order(:entry_date).paginate(page: params[:page], per_page: 35)
    end

    def show
      @payment = AccountingModule::Entry.find(params[:id])
    end
  end
end
