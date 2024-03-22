class ReportsController < AuthenticatedController
	def index
    @products = Product.all
	end
end
