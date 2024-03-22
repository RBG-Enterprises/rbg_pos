module Reports
  class ProductsController < AuthenticatedController
    def index
      @categories = Category.all
      @products = Product.all
      respond_to do |format|
        format.xlsx
      end
    end
  end
end
