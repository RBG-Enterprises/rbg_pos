# frozen_string_literal: true

class StoreFronts::SalesReturns::LineItems::CreateService < ActiveInteraction::Base
  object :line_item, class: StoreFrontModule::Orders::SalesOrder
  object :user

  def execute
    return if sales_order.returned_at

    ApplicationRecord.transaction do
      create_sales_return_order
      return_line_item
      update_stocks
      create_entry
      return_sales_order
    end
  end

  private

  def sales_order
    @sales_order ||= line_item.sales_order
  end

  def return_line_items
    sales_order.sales_order_line_items.each do |line_item|
      return_line_item(line_item)
    end
  end

  def return_line_item(line_item)
    @sales_return_order.sales_return_order_line_items.create!(
      stock: line_item.stock,
      quantity: line_item.quantity,
      unit_cost: line_item.unit_cost,
      total_cost: line_item.total_cost,
      product: line_item.product,
      unit_of_measurement: line_item.unit_of_measurement,
      bar_code: line_item.bar_code,
    )
  end

  def create_sales_return_order
    @sales_return_order = StoreFrontModule::Orders::SalesReturnOrder.create!(
      commercial_document: sales_order.commercial_document,
      store_front: sales_order.store_front,
      employee: user,
      date: DateTime.current,
      account_number: SecureRandom.uuid,
      voucher: sales_order.voucher,
      search_term: sales_order.search_term,
    )
  end

  def update_stocks
    sales_order.stocks.each do |stock|
      stock.update_available_quantity!
      stock.update_availability!
    end
  end

  def create_entry
    entry = AccountingModule::Entry.new(
      recorder: user,
      commercial_document: sales_order.commercial_document,
      entry_date: DateTime.current,
      description: "Sales Return for #{sales_order.account_number}",
    )

    entry.credit_amounts.build(
      amount: sales_order.total_cost_less_discount,
      account: sales_order.employee.cash_on_hand_account,
    )
    entry.credit_amounts.build(
      amount: sales_order.discount_amount,
      account: sales_order.sales_discount_account,
    )

    entry.credit_amounts.build(
      amount: sales_order.cost_of_goods_sold,
      account: sales_order.store_front.cost_of_goods_sold_account,
    )

    entry.debit_amounts.build(
      amount: sales_order.total_cost,
      account: sales_order.sales_revenue_account,
    )

    entry.debit_amounts.build(
      amount: sales_order.cost_of_goods_sold,
      account: sales_order.store_front.merchandise_inventory_account,
    )

    entry.save!
  end

  def return_sales_order
    sales_order.update!(returned_at: DateTime.current)
  end
end
