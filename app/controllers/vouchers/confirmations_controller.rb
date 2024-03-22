module Vouchers
  class ConfirmationsController < AuthenticatedController
    def create
      @voucher = Voucher.find(params[:voucher_id])
      Vouchers::Confirmation.new(voucher: @voucher).confirm!
      redirect_to "/", notice: 'transaction confirmed successfully'
    end
  end
end
