require 'will_paginate/array'
module Customers
  class AccountController < AuthenticatedController
    def index
      @customer = Customer.find(params[:customer_id])
      @payments = @customer.payment_entries.uniq.sort_by(&:entry_date).reverse.paginate(page: params[:page], per_page: 35)
    end
  end
end
