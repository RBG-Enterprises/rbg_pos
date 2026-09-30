class InventoriesController < ApplicationController
  # Preloads everything the index view touches so a page of N stocks fires a
  # bounded number of queries instead of ~14 per row. "In Stock" reads the
  # cached stocks.available_quantity column (maintained per transaction via
  # Stock#update_available_quantity!), so no per-row SUM queries.
  STOCK_INCLUDES = [
    :product,
    { purchase: { purchase_order: :supplier } },
    { sales: { sales_order: :commercial_document } },
    { stock_transfers: [:purchase_order] }
  ].freeze

  def index
    stocks = current_store_front.stocks.processed
      .order(Arel.sql("available_quantity DESC NULLS LAST, stocks.id DESC"))
    stocks = stocks.text_search(params[:search]) if params[:search].present?
    @pagy, @stocks = pagy(stocks.includes(*STOCK_INCLUDES))
  end
end
