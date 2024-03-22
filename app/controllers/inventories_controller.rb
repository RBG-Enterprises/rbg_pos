class InventoriesController < AuthenticatedController
  def index
    if params[:search].present?
      @pagy, @stocks = pagy(current_store_front.stocks.processed.text_search(params[:search]))
    else
      @pagy, @stocks  = pagy(current_store_front.stocks.processed.includes(:product,  :purchase =>[:purchase_order =>[:supplier]], :sales =>[:sales_order, :unit_of_measurement], :internal_uses =>[:unit_of_measurement], :stock_transfers =>[:purchase_order, :unit_of_measurement]))
    end
  end
end
