module ComputerRepairSection
  module WorkOrders
    class RefundsController < AuthenticatedController
      def new
        @work_order = WorkOrder.find(params[:work_order_id])
        @refund = AccountingModule::RefundProcessing.new
      end
      def create
        @work_order = WorkOrder.find(params[:work_order_id])
        @refund = AccountingModule::RefundProcessing.new(entry_params)
        if @refund.valid?
          @refund.process!
          redirect_to computer_repair_section_work_order_path(@work_order), notice: "Refund saved successfully."
        else
          render :new
        end
      end

      private
      def entry_params
        params.require(:accounting_module_refund_processing).
        permit(:employee_id, :date, :amount, :description, :work_order_id)
      end
    end
  end
end
