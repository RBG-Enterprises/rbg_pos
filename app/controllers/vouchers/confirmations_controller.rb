module Vouchers
  class ConfirmationsController < ApplicationController
    def create
      @voucher = Voucher.find(params[:voucher_id])
      Vouchers::Confirmation.new(voucher: @voucher).confirm!
      redirect_to safe_return_to("/"), notice: 'transaction confirmed successfully'
    end
  end
end 
