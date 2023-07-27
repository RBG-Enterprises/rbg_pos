module RepairServicesModule
  class RepairServiceOrderLineItemProcessingsController < ApplicationController
    def new
      @work_order = WorkOrder.find(params[:work_order_id])
      if params[:search].present?
        @stocks = current_store_front.stocks.processed.text_search(params[:search])
        @products = Product.text_search(params[:search]).all
      end
      @repair_service_order_line_item = RepairServicesModule::RepairServiceOrderLineItemProcessing.new
      @cart = current_cart
      @repair_service_order = RepairServicesModule::RepairServiceOrderProcessing.new
      @sales_order_line_items = @cart.sales_order_line_items
    end

    def create
      @work_order = WorkOrder.find(params[:work_order_id])
      @repair_service_order_line_item = RepairServicesModule::RepairServiceOrderLineItemProcessing.new(line_item_params)
      if @repair_service_order_line_item.valid?
          @repair_service_order_line_item.process!
          @repair_service_order_line_item.update_availability_for_cart(current_cart)
          redirect_to new_repair_services_module_work_order_repair_service_order_line_item_processing_url(@work_order), notice: "added to cart"
      else
        redirect_to new_repair_services_module_work_order_repair_service_order_line_item_processing_url(@work_order), alert: "Error"

      end
    end
    def destroy
      @work_order = WorkOrder.find(params[:work_order_id])
      @line_item  = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:id])
      @line_item.stock.update_availability_for_cart(current_cart)
      @line_item.destroy
      redirect_to new_repair_services_module_work_order_repair_service_order_line_item_processing_url(@work_order), notice: "Removed successfully"
    end

    private
    def line_item_params
      params.require(:repair_services_module_repair_service_order_line_item_processing).permit(:quantity,
        :unit_cost, :unit_of_measurement_id, :product_id, :cart_id, :work_order_id, :bar_code, :stock_id, :employee_id)
    end
  end
end
