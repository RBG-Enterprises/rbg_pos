module Customers
  class SettingsController < AuthenticatedController
    def index
      @customer = Customer.find(params[:customer_id])
    end
  end
end
