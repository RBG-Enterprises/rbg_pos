module Vouchers
  class DisbursementsController < AuthenticatedController
    def new
      @voucher = Voucher.find(params[:voucher_id])
      @disbursement = Vouchers::DisbursementProcessing.new
    end
    def create
      @voucher = Voucher.find(params[:voucher_id])
      @disbursement = Vouchers::DisbursementProcessing.new(disbursement_params)
      if @disbursement.valid?
        @disbursement.disburse!
        redirect_to voucher_url(@voucher), notice: "Voucher disbursed successfully"
      else
        render :new
      end
    end

    private
    def disbursement_params
      params.require(:vouchers_disbursement_processing).permit(
        :date,
        :disburser_id,
        :amount,
        :voucher_id,
        :description)
    end
  end
end
