class StoreController < ApplicationController
	def index
    if params[:search].present?
      @pagy, @stocks   = pagy(current_store_front.stocks.processed.includes(:product, :purchase => [:unit_of_measurement]).text_search(params[:search]))
      @pagy, @products = pagy(Product.text_search(params[:search]))
    end

		@sales_order_line_item = StoreFrontModule::LineItems::SalesOrderLineItemProcessing.new
		@cart = current_cart
		@sales_order = StoreFrontModule::Orders::SalesOrderProcessing.new
		if params[:customer_search].present?
			@pagy, @customers = pagy(current_business.customers.text_search(params[:customer_search]))
		end
		@customer = current_business.customers.find_by(id: params[:customer_id])
	end
end
