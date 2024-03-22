module Suppliers
  class ProductSelectionsController < AuthenticatedController
    def new
      @supplier = Supplier.find(params[:supplier_id])
      @purchase_order = Suppliers::PurchaseOrder.new
      @vouchers = Suppliers::VoucherAggregator.new(supplier: @supplier).unused_vouchers
      if params[:search].present?
        @pagy, @products = pagy(Product.text_search(params[:search]))
      else
        @pagy, @products = pagy(Product.all)
      end
    end
  end
end
