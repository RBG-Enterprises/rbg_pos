class VoucherAmountsController < AuthenticatedController
  def destroy
    @voucher_amount = Vouchers::VoucherAmount.find(params[:id])
    @voucher_amount.destroy
    redirect_to new_supplier_voucher_amount_url(@voucher_amount.commercial_document), notice: "Removed successfully"
  end
end
