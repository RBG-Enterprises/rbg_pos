# frozen_string_literal: true

# Shared overview data for the stock detail page
# (StoreFrontModule::StocksController + its tab controllers).
#
# The header rendered on every tab needs movement counts, totals and
# provenance without N+1s, and the Info tab needs a cross-store summary
# for the same barcode. All of it is computed here in a bounded number
# of indexed queries instead of in the views.
module StockOverview
  extend ActiveSupport::Concern

  private

  def load_stock_overview
    @movement_counts = {
      sales: @stock.sales.processed.count,
      stock_transfers: @stock.stock_transfers.processed.count,
      spoilages: @stock.spoilages.processed.count,
      internal_uses: @stock.internal_uses.processed.count,
    }
    purchase_order = @stock.purchase&.purchase_order
    @supplier_name = purchase_order&.supplier&.name
    @purchase_date = purchase_order&.date
    @same_barcode_summary = same_barcode_summary
  end

  # One row per store front carrying this barcode: total available quantity
  # and latest update. Two grouped SQL queries, no per-store N+1.
  def same_barcode_summary
    return [] if @stock.barcode.blank?

    scope = StoreFronts::Stock.processed.where(barcode: @stock.barcode)
    quantities = scope.group(:store_front_id).sum(:available_quantity)
    return [] if quantities.empty?

    updated = scope.group(:store_front_id).maximum(:updated_at)
    store_fronts = StoreFront.where(id: quantities.keys).index_by(&:id)
    quantities.map do |store_front_id, quantity|
      {
        store_front: store_fronts[store_front_id],
        available_quantity: quantity,
        last_updated_at: updated[store_front_id],
      }
    end.sort_by { |row| row[:store_front]&.name.to_s }
  end
end
