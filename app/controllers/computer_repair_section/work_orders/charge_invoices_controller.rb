module ComputerRepairSection
  module WorkOrders
    class ChargeInvoicesController < AuthenticatedController
      def new
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge_invoice = @work_order.build_charge_invoice
      end
      def create
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge_invoice = @work_order.build_charge_invoice(invoice_params)
        if @charge_invoice.valid?
          @charge_invoice.save
          redirect_to computer_repair_section_work_order_url(@work_order), notice: "Charge Invoice added successfully."
        else
          render :new
        end
      end

      private
      def invoice_params
        params.require(:invoices_charge_invoice).permit(:number, :date)
      end
    end
  end
end
