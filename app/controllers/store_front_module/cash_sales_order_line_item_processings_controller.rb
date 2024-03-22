module StoreFrontModule
  class CashSalesOrderLineItemProcessingsController < AuthenticatedController
    def new
      @customer  = Customer.find(params[:customer_id])
      @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.new
      if params[:search].present?
        @pagy,@stocks = pagy(current_store_front.stocks.text_search(params[:search]))
      else
        @pagy,@stocks = pagy(current_store_front.stocks)
      end
    end
    def create
      @customer  = Customer.find(params[:customer_id])
      @line_item = StoreFrontModule::LineItems::SalesOrderLineItem.create(line_item_params)
      if params[:search].present?
        @pagy,@stocks = pagy(current_store_front.stocks.text_search(params[:search]))
      else
        @pagy,@stocks = pagy(current_store_front.stocks)
      end
      if @line_item.valid?
        @line_item.save!
        redirect_to new_store_front_module_customer_cash_sales_order_line_item_processing_url(@customer), notice: 'added successfully'
      else
        render :new
      end
    end

    private
    def line_item_params
      params.require(:store_front_module_line_items_sales_order_line_item).
      permit(:cart_id, :quantity, :unit_cost, :total_cost, :bar_code, :stock_id, :unit_of_measurement_id)
    end
  end
end
