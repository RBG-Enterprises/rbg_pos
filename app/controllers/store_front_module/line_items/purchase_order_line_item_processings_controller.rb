module StoreFrontModule
  module LineItems
    class PurchaseOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @products = Product.text_search_with_barcode(params[:search]).all
        end
        @cart = current_cart
        @purchase_order_line_item = StoreFrontModule::LineItems::PurchaseOrderLineItemProcessing.new
        @purchase_order = StoreFrontModule::Orders::PurchaseOrderProcessing.new
        @purchase_order_line_items = @cart.purchase_order_line_items.order(created_at: :desc)

      end
      def create
        @line_item = StoreFrontModule::LineItems::PurchaseOrderLineItemProcessing.new(line_item_params)
        if @line_item.valid?
          @line_item.process!
          redirect_to new_store_front_module_purchase_order_line_item_processing_url, notice: "added successfully"
        else
          render :new
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::PurchaseOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to new_store_front_module_purchase_order_line_item_processing_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_purchase_order_line_item_processing).
        permit(:quantity, :unit_of_measurement_id, :product_id, :unit_cost, :total_cost, :bar_code, :cart_id)
      end
    end
  end
end
