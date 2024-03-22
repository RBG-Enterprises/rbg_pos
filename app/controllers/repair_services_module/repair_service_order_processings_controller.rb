module RepairServicesModule
  class RepairServiceOrderProcessingsController < AuthenticatedController
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @repair_service_order = RepairServicesModule::RepairServiceOrderProcessing.new(order_params)
      if @repair_service_order.valid?
        @repair_service_order.process!
        redirect_to computer_repair_section_work_order_url(@work_order), notice: "Order saved successfully"
      else
        redirect_to new_repair_services_module_work_order_repair_service_order_line_item_processing_url(@work_order), alert: "Error"
      end
    end

    private
    def order_params
    params.require(:repair_services_module_repair_service_order_processing).permit(:cart_id, :employee_id, :date, :customer_id, :work_order_id, :reference_number)
    end
  end
end
