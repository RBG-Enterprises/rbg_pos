module ComputerRepairSection
  class WorkOrderServiceChargesController < AuthenticatedController

    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @charge =ServiceCharge.create(service_charge_params)
      if @charge.valid?
        @charge.save
        @charge.additional!
        @work_order.work_order_service_charges.create(service_charge: @charge)
        redirect_to new_computer_repair_section_work_order_service_charge_url(@work_order), notice: "Additional Charge saved successfully"
      else
        render :new
      end
    end

    def destroy
      @charge = WorkOrderServiceCharge.find(params[:id])
      WorkOrders::ServiceChargeCancellation.new(charge: @charge).cancel!
      redirect_to new_computer_repair_section_work_order_service_charge_url(@charge.work_order), notice: "Removed successfully."
    end

    private
    def service_charge_params
      params.require(:service_charge).permit(:description, :amount)
    end
  end
end
