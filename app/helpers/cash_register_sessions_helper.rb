module CashRegisterSessionsHelper
  def cash_receipt_source_path(order)
    return if order.blank?

    order.is_a?(WorkOrder) ? computer_repair_section_work_order_path(order) : store_front_module_sales_order_path(order)
  end
end
