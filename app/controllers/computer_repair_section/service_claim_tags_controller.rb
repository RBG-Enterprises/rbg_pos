module ComputerRepairSection
  class ServiceClaimTagsController < AuthenticatedController
    def show
      @work_order = WorkOrder.find(params[:id])
      @work_order_update = @work_order.work_order_updates.build
      respond_to do |format|
        format.pdf do
          pdf = ServiceTagPdf.new(@work_order, view_context)
          send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Service Form.pdf"
        end
      end
    end
  end
end
