class CartsController < ApplicationController
	def destroy
		@cart = Cart.find(params[:id])
		@stock_ids = @cart.line_items.pluck(:stock_id)
		@cart.destroy

		update_stocks

		redirect_to store_index_url, notice: 'Cart emptied successfully.'
	end

	private

	def update_stocks
		StoreFronts::Stock.where(id: @stock_ids).each do |stock|
			stock.update_available_quantity!
			stock.update_availability!
		end
	end
end
