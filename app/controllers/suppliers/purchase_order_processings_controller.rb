module Suppliers
  class PurchaseOrderProcessingsController < AuthenticatedController
    def create
      @supplier = Supplier.find(params[:supplier_id])
      @purchase_order = Suppliers::PurchaseOrder.new(order_params)
      if @purchase_order.valid?
        @purchase_order.process!
        redirect_to supplier_url(@supplier), notice: 'saved successfully'
      else
        render :new
      end
    end

    private
    def order_params
      params.require(:suppliers_purchase_order).
      permit(:date, :voucher_id, :cart_id, :supplier_id, :employee_id, :store_front_id, :account_number)
    end
  end
end
