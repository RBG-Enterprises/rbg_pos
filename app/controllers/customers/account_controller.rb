require 'will_paginate/array'
module Customers
  class AccountController < ApplicationController
    def index
      @customer = Customer.find(params[:customer_id])
      payments = @customer.payment_entries.uniq.sort_by(&:entry_date).reverse
      payments = filter_payments(payments, params[:search]) if params[:search].present?
      @payments = payments.paginate(page: params[:page], per_page: 35)

      if request.xhr?
        render partial: "customers/partials/transactions",
               locals: { payments: @payments, customer: @customer },
               layout: false
      end
    end

    private

    # In-memory substring match (the list is already loaded, so this
    # stays instant even for hundreds of entries).
    def filter_payments(payments, term)
      query = term.to_s.downcase.strip
      payments.select do |payment|
        searchable_text(payment).include?(query)
      end
    end

    def searchable_text(payment)
      [
        payment.entry_date.try(:strftime, "%B %e, %Y"),
        payment.reference_number,
        payment.description,
        payment.debit_amounts.sum(:amount).to_s,
        payment.recorder_name,
        payment.user.try(:full_name)
      ].compact.join(" ").downcase
    end
  end
end
