module Products
  class StockTransfersController < AuthenticatedController
    def index
      @product         = current_business.products.find(params[:product_id])
      @pagy, @stock_transfer_orders = pagy(@product.stock_transfer_orders)
    end
  end
end
