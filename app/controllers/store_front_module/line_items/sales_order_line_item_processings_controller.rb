module StoreFrontModule
  module LineItems
    class SalesOrderLineItemProcessingsController < ApplicationController
      def create
        @sales_order_line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new(line_item_params)
        if @sales_order_line_item.valid?
          @sales_order_line_item.process!
          redirect_to store_index_url, notice: "added to cart"
        else
          redirect_to store_index_url, notice: "Error"
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to store_index_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_sales_order_line_item_processing).permit(:quantity,
          :unit_of_measurement_id, :product_id, :cart_id, :bar_code, :purchase_order_line_item_id)
      end
    end
  end
end