module Vouchers
  class VoucherAmountProcessingsController < AuthenticatedController
    def new
      @voucher_amount = Vouchers::VoucherAmountProcessing.new
    end
  end
end
