class StocksController < AuthenticatedController
	def index
		if params[:search].present?
			@stocks= Stock.text_search(params[:search]).paginate(page: params[:page], per_page: 20)
		else
		  @stocks = Stock.all.paginate(page: params[:page], per_page: 20)
		end
	end
	def new
		@stock = Stock.new
	end
	def create
		@stock = Stock.create(stock_params)
		@stock.branch = current_user.branch
    @stock.employee = current_user
		if @stock.save
			redirect_to new_stock_url, notice: "Stock saved successfully."
      @stock.set_name
		else
			render :new
		end
	end
	def edit
		@stock = Stock.find(params[:id])
	end
  def update
		@stock = Stock.find(params[:id])
		@stock.update(stock_params)
    @stock.employee = current_user
		if @stock.valid?
			@stock.save
			redirect_to product_url(@stock.product), notice: 'Stock updated successfully.'
      @stock.set_name
    else
      render :edit
		end
	end
	def show
		@stock = current_store_front.stocks.processed.includes(:unit_of_measurement, :stock_transfers =>[:unit_of_measurement]).find(params[:id])
	end

	def destroy
		@stock = Stock.find(params[:id])
		authorize @stock
    if @stock.line_items.present?
      redirect_to stocks_url, alert: "Stock has items sold. Stock cannot be deleted."
    else
		  @stock.destroy
		  redirect_to stocks_url, notice: "Stock deleted successfully."
    end
	end

	private
	def stock_params
		params.require(:stock).permit(:product_id, :date, :stock_type, :supplier_id, :unit_cost, :total_cost, :quantity, :retail_price, :wholesale_price, :barcode, :name, :origin_branch_id)
	end
end
