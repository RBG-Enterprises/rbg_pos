module StoreFrontModule
  module LineItems
    class PurchaseReturnOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @products = Product.text_search(params[:search]).all
          @line_items = StoreFrontModule::LineItems::PurchaseOrderLineItem.processed.for_store_front(current_store_front).text_search(params[:search])
        end
        @cart = current_cart
        @purchase_return_order_line_item = StoreFrontModule::LineItems::PurchaseReturnOrderLineItemProcessing.new
        @purchase_return_order = StoreFrontModule::Orders::PurchaseReturnOrderProcessing.new
        @purchase_return_order_line_items = @cart.purchase_return_order_line_items.order(created_at: :desc)
      end
      def create
        @line_item = StoreFrontModule::LineItems::PurchaseReturnOrderLineItemProcessing.new(line_item_params)
        if @line_item.process!
          redirect_to new_store_front_module_purchase_return_order_line_item_processing_url, notice: "added successfully"
        else
          redirect_to new_store_front_module_purchase_return_order_line_item_processing_url, alert: "error"
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::PurchaseReturnOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to new_store_front_module_purchase_return_order_line_item_processing_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_purchase_return_order_line_item_processing).
        permit(
          :quantity,
          :unit_of_measurement_id,
          :product_id,
          :unit_cost,
          :total_cost,
          :bar_code,
          :cart_id,
          :purchase_order_line_item_id)
      end
    end
  end
end
