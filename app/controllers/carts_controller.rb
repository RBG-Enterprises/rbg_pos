class CartsController < AuthenticatedController
	def destroy
		@cart = Cart.find(params[:id])
		@cart.destroy
		redirect_to store_index_url, notice: 'Cart emptied successfully.'
	end
end
