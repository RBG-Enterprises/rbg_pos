module Suppliers
  class PurchaseLineItemsController < AuthenticatedController
    def new
      @supplier = Supplier.find(params[:supplier_id])
      @product  = Product.find(params[:product_id])
      @purchase = Suppliers::PurchaseLineItem.new
    end
    def create
      @supplier = Supplier.find(params[:supplier_id])
      @product  = Product.find(params[:suppliers_purchase_line_item][:product_id])
      @purchase = Suppliers::PurchaseLineItem.new(line_item_params)
      if @purchase.valid?
        @purchase.process!
        redirect_to new_supplier_product_selection_url(supplier_id: @supplier.id), notice: 'added successfully'
      else
        render :new
      end
    end

    private
    def line_item_params
      params.require(:suppliers_purchase_line_item).
      permit(:quantity, :unit_cost, :total_cost, :barcode, :unit_of_measurement_id, :product_id, :selling_price, :store_front_id, :cart_id)
    end
  end
end
