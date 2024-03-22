module Suppliers
  class VoucherConfirmationsController < AuthenticatedController
    def create
      @supplier = Supplier.find(params[:supplier_id])
      @confirmation = Suppliers::VoucherConfirmation.new(voucher_params)
      @confirmation.confirm!
      redirect_to supplier_url(@supplier), notice: 'confirmed successfully'
    end

    private
    def voucher_params
      params.require(:suppliers_voucher_confirmation).
      permit(:supplier_id, :voucher_id)
    end
  end
end
