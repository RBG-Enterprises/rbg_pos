module Suppliers
  class PurchaseOrdersController < AuthenticatedController
    def index
      @supplier      = Supplier.find(params[:supplier_id])
      @pagy, @orders = pagy(@supplier.purchase_orders.order(date: :desc))
    end
  end
end
