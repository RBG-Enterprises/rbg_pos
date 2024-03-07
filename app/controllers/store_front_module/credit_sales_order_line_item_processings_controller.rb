module StoreFrontModule
  class CreditSalesOrderLineItemProcessingsController < ApplicationController
    def new
      @customer = Customer.find(params[:customer_id])
      if params[:search].present?
        @pagy, @stocks   = pagy(current_store_front.stocks.processed.available.includes(:product, :purchase => [:unit_of_measurement]).text_search(params[:search]))
        @pagy, @products = pagy(Product.text_search(params[:search]))
      end
      @cart = current_cart
      @line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new
      @sales_order_line_items = @cart.sales_order_line_items.order(created_at: :desc)
      @credit_sales_order = StoreFrontModule::Orders::CreditSalesOrderProcessing.new
    end
    def create
      @customer = Customer.find(params[:customer_id])
      @sales_order_line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new(line_item_params)
      if @sales_order_line_item.valid?
        @sales_order_line_item.process!
        redirect_to new_store_front_module_customer_credit_sales_order_line_item_processing_url(@customer), notice: "added to cart"
      else
        redirect_to new_store_front_module_customer_credit_sales_order_line_item_processing_url(@customer), alert: "Error"
      end
    end
    def destroy
      @customer = Customer.find(params[:customer_id])
      @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.find(params[:id])
      @line_item.destroy
      redirect_to new_store_front_module_customer_credit_sales_order_line_item_processing_url(@customer), notice: "Removed successfully"
    end
    private
    def line_item_params
      params.require(:store_front_module_line_items_sales_order_line_item_processing).permit(:quantity,
        :unit_of_measurement_id, :unit_cost, :product_id, :cart_id, :bar_code, :stock_id, :store_front_id)
    end
  end
end
