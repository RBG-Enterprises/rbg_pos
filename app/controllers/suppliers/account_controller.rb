module Suppliers
  class AccountController < AuthenticatedController
    def index
      @supplier = Supplier.find(params[:supplier_id])
    end
  end
end
