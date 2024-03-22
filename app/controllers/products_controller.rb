require 'will_paginate/array'
class ProductsController < AuthenticatedController
	def index
    if params[:search].present?
      @pagy, @products = pagy(Product.includes(:category, :unit_of_measurements, stocks: [:purchase]).text_search_with_barcode(params[:search]))
    else
      @pagy, @products = pagy(Product.includes(:unit_of_measurements, :category).order(:name))
    end
    @categories = Category.all
    @registry = Registry.new
    respond_to do |format|
      format.html
      format.xlsx
      format.pdf do
        pdf = ProductsPdf.new(@products, view_context)
          send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Products PDF Report.pdf"
      end
    end
  end

  def out_of_stock
    @out_of_stock_products = (Product.out_of_stock).paginate(page: params[:page], per_page: 35)
  end
  def low_on_stock
    @low_on_stock_products = (Product.low_on_stock).paginate(page: params[:page], per_page: 35)
	end

	def new
		@product = Product.new
		authorize @product
		@category = Category.new
	end

	def create
		@product = Product.create(product_params)
		if @product.valid?
			@product.save
			redirect_to @product, notice: "Product saved successfully."
		else
			render :new
		end
	end

	def show
		@product = Product.find(params[:id])

		@orders = @product.sales_orders.all.paginate(page: params[:page], per_page: 30)

	end
	def edit
		@product = Product.find(params[:id])
		authorize @product
	end
	def update
		@product = Product.find(params[:id])
		authorize @product
		@product.update(product_params)
		if @product.valid?
			@product.save
			redirect_to product_settings_url(@product), notice: "Product updated successfully"
		else
			render :edit
		end
	end
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to products_url notice: "Product removed successfully"
  end


	private
	def product_params
		params.require(:product).permit(:category_id, :avatar, :name, :description, :retail_price, :wholesale_price, :unit, :low_stock_count)
	end
end
