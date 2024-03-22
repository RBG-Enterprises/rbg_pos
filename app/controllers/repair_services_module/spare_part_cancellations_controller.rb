module RepairServicesModule
  class SparePartCancellationsController < AuthenticatedController
    def destroy
      @work_order = WorkOrder.find(params[:work_order_id])
      @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:line_item_id])
      @cancellation = ::WorkOrders::SpareParts::Cancellation.new(
        line_item: @line_item,
        work_order: @work_order,
        employee: current_user
      ).cancel!
      redirect_to computer_repair_section_work_order_url(@work_order), notice: 'Spare part cancelled successfully'
    end
  end
end
