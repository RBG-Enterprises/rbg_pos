module StoreFrontModule
  module Orders
    module SalesOrders
      class AdditionalOtherSalesItemsController < AuthenticatedController
        def new
          @cart = current_cart
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @other_sale = StoreFrontModule::LineItems::OtherSalesItemProcessing.new
          @additional_other_sales_order = StoreFrontModule::Orders::OtherSalesLineItemOrderProcessing.new
        end
        def create
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @other_sale = StoreFrontModule::LineItems::OtherSalesItemProcessing.new(other_sale_params)
          if @other_sale.valid?
            @other_sale.process!
            redirect_to new_store_front_module_sales_order_additional_other_sales_item_url(@sales_order), notice: "Other sales item saved successfully."
          else
            render :new
          end
        end

        def destroy
          @sales_order = StoreFrontModule::Orders::SalesOrder.find(params[:sales_order_id])
          @item = OtherSalesLineItem.find(params[:id])
          @item.destroy
          redirect_to new_store_front_module_sales_order_additional_other_sales_item_url(@sales_order), notice: "Other sales item saved successfully."
        end

        private
        def other_sale_params
          params.require(:store_front_module_line_items_other_sales_item_processing).permit(:amount, :reference_number, :description, :date, :cart_id)
        end
      end
    end
  end
end
