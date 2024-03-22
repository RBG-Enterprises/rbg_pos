module StoreFrontModule
  module LineItems
    class InternalUseOrderLineItemProcessingsController < AuthenticatedController
      def new
        if params[:search].present?
          @pagy, @stocks   = pagy(current_store_front.stocks.processed.text_search(params[:search]))
          @pagy, @products = pagy(Product.text_search(params[:search]))
        end
        @cart = current_cart
        @internal_use_order_line_item = StoreFrontModule::LineItems::InternalUseOrderLineItemProcessing.new
        @internal_use_order = StoreFrontModule::Orders::InternalUseOrderProcessing.new
        @internal_use_order_line_items = @cart.internal_use_order_line_items.order(created_at: :desc)
      end
      def create
        @line_item = StoreFrontModule::LineItems::InternalUseOrderLineItemProcessing.new(line_item_params)
        if @line_item.valid?
          @line_item.process!
          redirect_to new_store_front_module_internal_use_order_line_item_processing_url, notice: "added to cart"
        else
          render :new
        end
      end
      def destroy
        @line_item = StoreFrontModule::LineItems::InternalUseOrderLineItem.find(params[:id])
        @line_item.destroy
        redirect_to new_store_front_module_internal_use_order_line_item_processing_url, notice: "Removed successfully"
      end

      private
      def line_item_params
        params.require(:store_front_module_line_items_internal_use_order_line_item_processing).
        permit(:quantity, :unit_of_measurement_id, :product_id, :unit_cost, :total_cost, :bar_code, :cart_id, :stock_id)
      end
    end
  end
end
