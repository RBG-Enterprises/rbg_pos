module RepairServicesModule
  class PaymentProcessingsController < ApplicationController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = RepairServicesModule::PaymentProcessing.new
    end
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = RepairServicesModule::PaymentProcessing.new(payment_params)
      if @payment.valid?
        @payment.process!
        redirect_to repair_services_module_work_order_payment_processing_path(@work_order, @payment.voucher),
                    notice: "Review and confirm the payment."
      else
        render :new
      end
    end

    def show
      @work_order = WorkOrder.find(params[:work_order_id])
      @voucher = Voucher.find(params[:id])
    end

    private
    def payment_params
      params.require(:repair_services_module_payment_processing).permit(:description, :amount, :date, :employee_id, :customer_id, :work_order_id, :expense_amount, :expense_account_id)
    end
  end
end
