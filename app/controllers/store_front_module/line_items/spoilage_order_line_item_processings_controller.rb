module StoreFrontModule
  module LineItems
    class SpoilageOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @pagy, @stocks   = pagy(current_store_front.stocks.processed.text_search(params[:search]))
          @pagy, @products = pagy(Product.text_search(params[:search]))
        end
        @cart = current_cart
        @spoilage_order_line_item = StoreFrontModule::LineItems::SpoilageOrderLineItemProcessing.new
        @spoilage_order = StoreFrontModule::Orders::SpoilageOrderProcessing.new
        @spoilage_order_line_items = @cart.spoilage_order_line_items.order(created_at: :desc)
      end

      def create
        @spoilage_order_line_item = StoreFrontModule::LineItems::SpoilageOrderLineItemProcessing.new(line_item_params)
        if @spoilage_order_line_item.valid?
          @spoilage_order_line_item.process!
          redirect_to new_store_front_module_spoilage_order_line_item_processing_path, notice: "added to cart"
        else
          render :new
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::SpoilageOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to new_store_front_module_spoilage_order_line_item_processing_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_spoilage_order_line_item_processing).permit(:quantity,
          :unit_of_measurement_id, :product_id, :cart_id, :adjustment, :stock_id)
      end
    end
  end
end
