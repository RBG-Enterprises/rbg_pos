module StoreFrontModule
  module SalesOrderLineItems
    class SalesReturnsController < AuthenticatedController
      def new
        @sales_order_line_item = current_store_front.sales_order_line_items.find(params[:sales_order_line_item_id])
        @sales_return          = StoreFrontModule::LineItems::SalesReturnProcessing.new
      end
      def create
        @sales_order_line_item = current_store_front.sales_order_line_items.find(params[:store_front_module_line_items_sales_return_processing][:sales_order_line_item_id])
        @sales_return          = StoreFrontModule::LineItems::SalesReturnProcessing.new(line_item_params)

        if @sales_return.valid?
          @sales_return.process!
          redirect_to store_front_module_sales_order_url(@sales_order_line_item.sales_order), notice: 'Items returned successfully'
        else
          render :edit
        end
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_sales_return_processing).
        permit(:quantity, :sales_order_line_item_id, :employee_id, :date)
      end
    end
  end
end
