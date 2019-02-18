module StoreFrontModule
  module Orders
    module SalesOrders
      class AdditionalLineItemsController < ApplicationController
        def new
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @cart = current_cart
          if params[:search].present?
      		  @products = Product.text_search(params[:search]).all.paginate(page: params[:page], per_page: 25)
            @line_items = StoreFrontModule::LineItems::PurchaseOrderLineItem.processed.text_search(params[:search])
          end
      		@sales_order_line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new
          @additional_line_item_processing = StoreFrontModule::LineItems::AdditionalSalesOrderLineItemProcessing.new(cart: @cart, sales_order: @sales_order, employee: current_user)

        end

        def create
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @sales_order_line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new(additional_line_item_params)
          if @sales_order_line_item.valid?
            @sales_order_line_item.process!
            redirect_to new_store_front_module_sales_order_additional_line_item_url(@sales_order), notice: "added to cart"
          else
            redirect_to store_index_url, notice: "Error"
          end
        end

        def destroy
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:id])
          @line_item.destroy
          redirect_to new_store_front_module_sales_order_additional_line_item_url(@sales_order), notice: "Removed successfully."

        end

        private
        def additional_line_item_params
          params.require(:store_front_module_line_items_sales_order_line_item_processing).
          permit(:unit_of_measurement_id,
                        :quantity,
                        :cart_id,
                        :product_id,
                        :unit_cost,
                        :store_front_id,
                        :bar_code,
                        :purchase_order_line_item_id)
        end
      end
    end
  end
end
