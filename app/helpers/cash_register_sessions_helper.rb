module CashRegisterSessionsHelper
  # Deep link for a cash receipt row: sales order payments open their sales
  # order, repair payments open their work order, and other sales open
  # their other sale page (addressed by voucher, like OtherSalesController).
  # Anything unrecognized gets no link rather than a wrong one.
  def cash_receipt_source_path(row)
    voucher = row[:voucher]
    order = row[:order]
    return if order.blank?

    if voucher.is_a?(Vouchers::OtherSaleVoucher)
      other_sale_path(voucher)
    elsif order.is_a?(WorkOrder)
      computer_repair_section_work_order_path(order)
    elsif order.is_a?(StoreFrontModule::Orders::SalesOrder)
      store_front_module_sales_order_path(order)
    end
  end

  # Stock page for an items-summary row. Only links when the stock's
  # branch matches the branch currently viewed — StocksController scopes
  # to the current store front, so anything else would 404.
  def item_stock_path(row)
    return if row[:stock_id].blank?
    if row[:stock_store_front_id].present? && row[:stock_store_front_id] != current_store_front&.id
      return
    end

    store_front_module_stock_path(row[:stock_id])
  end
end
