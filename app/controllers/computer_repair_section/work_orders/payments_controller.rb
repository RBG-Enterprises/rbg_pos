module ComputerRepairSection
  module WorkOrders
    class PaymentsController < AuthenticatedController
      def new
        @work_order = WorkOrder.find(params[:work_order_id])
        @entry = AccountingModule::WorkOrderPaymentProcessing.new
      end
      def create
        @work_order = WorkOrder.find(params[:work_order_id])
        @entry = AccountingModule::WorkOrderPaymentProcessing.new(entry_params)
        if @entry.valid?
          @entry.save
          redirect_to computer_repair_section_work_order_path(@work_order), notice: "Payment saved successfully."
        else
          render :new
        end
      end

      private
      def entry_params
        params.require(:accounting_module_work_order_payment_processing).permit(:user_id, :expense_amount, :work_order_id, :entry_date, :reference_number, :description, :amount, :expense_account_id)
      end
    end
  end
end
