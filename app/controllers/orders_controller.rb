class OrdersController < AuthenticatedController
	def index
    if params[:search].present?
      @orders = Order.text_search(params[:search]).paginate(page: params[:page], per_page: 35)
    elsif params[:from_date].present? && params[:to_date].present?
      @from_date = Time.parse(params[:from_date])
      @to_date = Time.parse(params[:to_date])
      @orders = Order.ordered_on(from_date: @from_date, to_date: @to_date).paginate(page: params[:page], per_page: 35)
    else
		  @orders = Order.all.order(date: :desc).paginate(page: params[:page], per_page: 35)
    end
		authorize @orders
	end
	def new
		@cart = current_cart
		@order = Order.new
		@order.build_payment
	end
	def create
		@cart = current_cart
		@order = Order.new(order_params)
    @order.employee = current_user
		if @order.valid?
			@order.add_line_items_from_cart(@cart)
			@order.save!
			redirect_to @order, notice: "Order saved successfully."
			@order.create_entry_for_order
		else
			render :new
		end
	end

	def show
		@order = Order.find(params[:id])
		respond_to do |format|
			format.html
      format.xlsx
			format.pdf do
				pdf = OrderPdf.new(@order, view_context)
          send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Order.pdf"
			end
		end
	end
	def destroy
		@order = Order.find(params[:id])
		@order.destroy
		redirect_to orders_url, alert: "Order deleted successfully."
	end

	private
	def order_params
		params.require(:order).permit(:search_term, :internal_use, :technician_id, :reference_number, :customer_id, :date, payment_attributes: [:internal_use, :technician_id, :mode_of_payment, :discount_amount, :cash_tendered, :change, :total_cost, :total_cost_less_discount])
	end
end
