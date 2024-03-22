module RepairServicesModule
  class PaymentProcessingsController < AuthenticatedController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = RepairServicesModule::PaymentProcessing.new
    end
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = RepairServicesModule::PaymentProcessing.new(payment_params)
      if @payment.valid?
        @payment.process!
        redirect_to computer_repair_section_work_order_url(@work_order), notice: "Payment saved successfully"
      else
        render :new
      end
    end
    private
    def payment_params
      params.require(:repair_services_module_payment_processing).permit(:description, :amount, :date, :employee_id, :customer_id, :work_order_id, :expense_amount, :expense_account_id)
    end
  end
end
