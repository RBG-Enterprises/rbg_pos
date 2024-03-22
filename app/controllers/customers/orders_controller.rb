module Customers
  class OrdersController < AuthenticatedController
    def index
      @customer = Customer.find(params[:customer_id])
      if params[:search].present?
        @orders = @customer.sales_orders.text_search(params[:search]).paginate(page: params[:page], per_page: 50)
      else
        @orders = @customer.sales_orders.order(date: :desc).all.paginate(page: params[:page], per_page: 50)
      end
    end
    def edit
      @customer = Customer.find(params[:customer_id])
      @order = Order.find(params[:id])
    end
    def update
      @customer = Customer.find(params[:customer_id])
      @order = Order.find(params[:id])
      @order.update(order_params)
      if @order.valid?
        @order.save
        redirect_to customer_orders_url(@customer), notice: "Order updated successfully."
      else
        render :edit
      end
    end

    private
    def order_params
      params.require(:store_front_module_orders_sales_order).
      permit(:reference_number, :description)
    end
  end
end
