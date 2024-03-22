module WorkOrders
  class PaymentsController < AuthenticatedController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = WorkOrders::PaymentProcessing.new
    end
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @payment = WorkOrders::PaymentProcessing.new(payment_params)
      if @payment.valid?
        @payment.process!
        redirect_to computer_repair_section_work_order_url(@work_order), notice: "Payment processed successfully."
      else
        render :new
      end
    end

    private
    def payment_params
      params.require(:work_orders_payment_processing).permit(:recorder_id, :amount, :customer_id)
    end
  end
end
