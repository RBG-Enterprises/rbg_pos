module Suppliers
  class VouchersController < ApplicationController
    def index
      @supplier = Supplier.find(params[:supplier_id])
      @pagy, @vouchers = pagy(@supplier.vouchers.order(created_at: :desc))
    end
    def create
      @supplier = Supplier.find(params[:supplier_id])
      @voucher  = Suppliers::VoucherProcessing.new(voucher_params)
      if @voucher.valid?
        @voucher.process!
        redirect_to supplier_voucher_url(supplier_id: @supplier.id, id: @voucher.find_voucher.id), notice: "Voucher created successfully."
      else
        render :new
      end
    end
    def show
      @supplier     = Supplier.find(params[:supplier_id])
      @voucher      = @supplier.vouchers.find(params[:id])
      @confirmation = Suppliers::VoucherConfirmation.new
    end

    private
    def voucher_params
      params.require(:suppliers_voucher_processing).permit(
      :account_number,
      :supplier_id,
      :cart_id,
      :reference_number,
      :date,
      :description,
      :preparer_id)
    end
  end
end
