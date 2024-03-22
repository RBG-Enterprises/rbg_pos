module ComputerRepairSection
  module WorkOrders
    class EndorsementsController < AuthenticatedController
      def edit
        @work_order = current_store_front.work_orders.find(params[:work_order_id])
      end

      def update
        @work_order = current_store_front.work_orders.find(params[:work_order_id])
        @work_order.update(work_order_params)
        if @work_order.valid?
          @work_order.save!
          redirect_to computer_repair_section_work_order_url(@work_order), notice: 'saved successfully.'
        else
          render :edit
        end
      end

      private
      def work_order_params
        params.require(:work_order).permit(:technician_id)
      end
    end
  end
end
