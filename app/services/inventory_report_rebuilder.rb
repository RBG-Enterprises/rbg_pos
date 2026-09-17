# frozen_string_literal: true

# Rebuilds the derived InventoryReport table from LineItem records.
#
#   LineItem -> InventoryReportRebuilder -> InventoryReport
#
# Idempotent and safe to run repeatedly. Uses find_or_initialize_by(stock:)
# so existing rows are updated, never duplicated. Works even after
# InventoryReport.delete_all since LineItem history is the source of truth.
#
# Creating a LineItem must NOT trigger this; run it from
# InventoryReportRebuilderJob on a schedule instead.
class InventoryReportRebuilder
  PURCHASE_TYPE = "StoreFrontModule::LineItems::PurchaseOrderLineItem"
  SALES_TYPE = "StoreFrontModule::LineItems::SalesOrderLineItem"
  TRANSFER_TYPE = "StoreFrontModule::LineItems::StockTransferOrderLineItem"
  SPOILAGE_TYPE = "StoreFrontModule::LineItems::SpoilageOrderLineItem"
  INTERNAL_USE_TYPE = "StoreFrontModule::LineItems::InternalUseOrderLineItem"
  SALES_RETURN_TYPE = "StoreFrontModule::LineItems::SalesReturnOrderLineItem"
  PURCHASE_RETURN_TYPE = "StoreFrontModule::LineItems::PurchaseReturnOrderLineItem"
  FOR_WARRANTY_TYPE = "StoreFrontModule::LineItems::ForWarrantyOrderLineItem"

  def self.call
    new.call
  end

  def call
    totals_by_stock = grouped_totals

    StoreFronts::Stock.find_each(batch_size: 50) do |stock|
      puts "rebuild inventory for #{stock.id}"
      totals = totals_by_stock[stock.id] || {}
      purchases = totals[PURCHASE_TYPE] || 0
      sales = totals[SALES_TYPE] || 0
      spoilage = totals[SPOILAGE_TYPE] || 0
      internal_use = totals[INTERNAL_USE_TYPE] || 0
      transfers = totals[TRANSFER_TYPE] || 0
      sales_returns = totals[SALES_RETURN_TYPE] || 0
      purchase_returns = totals[PURCHASE_RETURN_TYPE] || 0
      for_warranties = totals[FOR_WARRANTY_TYPE] || 0
      # Mirrors StoreFronts::Stock#balance.
      available = stock.count_adjustment +
        purchases +
        sales_returns -
        purchase_returns -
        transfers -
        sales -
        internal_use -
        spoilage -
        for_warranties

      report = InventoryReport.find_or_initialize_by(stock: stock)
      report.product_id = stock.product_id
      report.store_front_id = stock.store_front_id
      report.purchases = purchases
      report.sales = sales
      report.spoilage = spoilage
      report.internal_use = internal_use
      report.transfers = transfers
      report.sales_returns = sales_returns
      report.purchase_returns = purchase_returns
      report.for_warranties = for_warranties
      report.available = available
      report.save!
    end
  end

  private

  # One bulk query: { stock_id => { type => sum(quantity) } }
  def grouped_totals
    sums = LineItem.where(stock_id: StoreFronts::Stock.select(:id))
      .group(:stock_id, :type)
      .sum(:quantity)
    sums.each_with_object({}) do |((stock_id, type), sum), memo|
      memo[stock_id] ||= {}
      memo[stock_id][type] = sum || 0
    end
  end
end
