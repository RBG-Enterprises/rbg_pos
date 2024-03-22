module Branches
  class StockTransfersController < AuthenticatedController
    def new
      @branch = Branch.find(params[:branch_id])
      if params[:line_item_search].present?
        @stocks = Stock.text_search(params[:line_item_search]).paginate(page: params[:page], per_page: 30)
      else
        @stocks = Stock.text_search(params[:search]).paginate(page: params[:page], per_page: 30)
      end
      @line_item = LineItem.new
      @cart = current_cart
      @order = Order.new
    end
    def create
      @stock_transfer = StockTransfer.create!(stock_transfer_params)
      @cart = current_cart
      @stock_transfer.add_line_items_from_cart(@cart)
      @stock_transfer.create_entry
      redirect_to @stock_transfer, notice: "Stock Transfer saved successfully."
    end

    private
    def stock_transfer_params
      params.require(:stock_transfer).permit(:destination_branch_id, :employee_id)
    end
  end
end
