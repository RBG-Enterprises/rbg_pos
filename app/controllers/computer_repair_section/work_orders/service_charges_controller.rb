module ComputerRepairSection
  module WorkOrders
    class ServiceChargesController < AuthenticatedController
      def new
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge = @work_order.work_order_service_charges.build
      end
      def create
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge = @work_order.work_order_service_charges.create(service_charge_params)
        if @charge.valid?
          @charge.save
          @work_order.service_charge_entry(@charge)
          redirect_to new_computer_repair_section_work_order_service_charge_url(@work_order), notice: "Charge saved successfully"
        else
          render :new
        end
      end

      def destroy
        @work_order = WorkOrder.find(params[:work_order_id])
        @service_charge = @work_order.work_order_service_charges.find(params[:id])
        ::WorkOrders::ServiceChargeCancellation.new(service_charge: @service_charge).cancel!
        redirect_to new_repair_services_module_work_order_service_charge_processing_path(@service_charge.work_order), notice: "Service charge deleted successfully"
      end

      private
      def service_charge_params
        params.require(:work_order_service_charge).permit(:service_charge_id, :user_id)
      end
    end
  end
end
