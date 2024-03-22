module ComputerRepairSection
  module WorkOrders
    class AdditionalChargesController < AuthenticatedController
      def new
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge = @work_order.work_order_service_charges.build
      end
      def create
        @work_order = WorkOrder.find(params[:work_order_id])
        @charge =ServiceCharge.create(service_charge_params)
        if @charge.valid?
          @charge.save
          @charge.additional!
          @service_charge = @work_order.work_order_service_charges.create(service_charge_id: @charge.id, user_id: current_user.id)
          @work_order.service_charge_entry(@service_charge)
          redirect_to new_computer_repair_section_work_order_service_charge_url(@work_order), notice: "Additional Charge saved successfully"
        else
          render :new
        end
      end
      private
      def service_charge_params
        params.require(:service_charge).permit(:description, :amount)
      end
    end
  end
end
