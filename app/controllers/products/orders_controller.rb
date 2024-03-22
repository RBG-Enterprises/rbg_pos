module Products
  class OrdersController < AuthenticatedController
    def index
      @product       = Product.find(params[:product_id])
      @pagy, @orders = pagy(@product.sales_orders.for_store_front(current_store_front))
    end
  end
end
