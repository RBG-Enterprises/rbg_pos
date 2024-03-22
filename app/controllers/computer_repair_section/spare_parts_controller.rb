module ComputerRepairSection
  class SparePartsController < AuthenticatedController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      @products = Product.text_search(params[:search])
      @work_order_line_item = RepairServicesModule::WorkOrderLineItemProcessing.new
      @cart = current_cart
      @order = Order.new
    end
    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @spare_part = StoreFrontModule::LineItems::WorkOrderLineItemProcessing.new(line_item_params)
      if @spare_part.save
        @work_order.create_order(@spare_part)
        @work_order.spare_part_entry(@spare_part)
        redirect_to new_computer_repair_section_work_order_spare_part_url(@work_order), notice: "Added successfully"
      else
        render :new
      end
    end
    def destroy
    @line_item = LineItem.find(params[:id])
    @line_item.destroy
    @line_item.remove_entry
    redirect_to new_computer_repair_section_work_order_spare_part_url(@line_item.work_order), notice: "Removed successfully"
  end

    private
    def line_item_params
      params.require(:line_item).permit(:stock_id, :unit_cost, :total_cost, :quantity, :markup_amount, :user_id)
    end
  end
end
