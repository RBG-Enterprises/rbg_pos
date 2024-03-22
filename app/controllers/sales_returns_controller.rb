class SalesReturnsController < AuthenticatedController
	def index
		@sales_returns = SalesReturn.all.order(date: :desc).paginate(page: params[:page], per_page: 30)
	end
end
