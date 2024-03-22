module RepairServicesModule
  class ServiceChargeProcessingsController < AuthenticatedController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      @service_charge = RepairServicesModule::ServiceChargeProcessing.new
    end
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @service_charge = RepairServicesModule::ServiceChargeProcessing.new(service_charge_params)
      if @service_charge.valid?
        @service_charge.process!
        redirect_to new_repair_services_module_work_order_service_charge_processing_url(@work_order), notice: "Service Charge added successfully"
      else
        render :new
      end
    end

    private
    def service_charge_params
      params.require(:repair_services_module_service_charge_processing).permit(:description, :amount, :work_order_id, :employee_id, :date, :customer_id)
    end
  end
end
