require 'will_paginate/array'
module Products
  class StocksController < AuthenticatedController
    def index
      @product       = Product.find(params[:product_id])
      @pagy, @stocks = pagy(@product.stocks.processed.where(store_front: current_store_front))
    end
    def new
      @product = Product.find(params[:product_id])
      @stock = @product.stocks.build
    end
    def create
      @product        = Product.find(params[:product_id])
      @stock          = @product.stocks.create(stock_params)
      @stock.branch   = current_user.branch
      @stock.employee = current_user
      if @stock.save
        redirect_to new_product_stock_url(@product), notice: "Stock saved successfully."
      else
        render :new
      end
    end
    def edit
      @product = Product.find(params[:product_id])
      @stock = @product.stocks.find(params[:id])
      @purchase = @stock.purchase
    end

    def update
      @product = Product.find(params[:product_id])
      @stock = @product.stocks.find(params[:id])
      @purchase = @stock.purchase
      @purchase.update(purchase_params)
      if @purchase.valid?
        @purchase.save!
        @stock.update(barcode: @purchase.bar_code)
        @stock.save
        redirect_to product_stocks_url(@product), notice: 'Stock updated successfully.'
      else
        render :edit
      end
    end

    def show
      @product = Product.find(params[:product_id])
      @stock   = @product.stocks.find(params[:id])
    end

    def destroy
      @stock = Stock.find(params[:id])
      authorize @stock
      @stock.destroy
      redirect_to stocks_url, alert: "Stock deleted successfully."
    end

    private
    def purchase_params
      params.require(:store_front_module_line_items_purchase_order_line_item).permit(:unit_of_measurement_id, :unit_cost, :total_cost, :quantity, :bar_code)
    end
  end
end
