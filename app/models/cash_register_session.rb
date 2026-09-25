# frozen_string_literal: true

class CashRegisterSession < ApplicationRecord
  enum status: { open: 0, closed: 1 }

  belongs_to :employee, class_name: "User"
  belongs_to :cash_account, class_name: "AccountingModule::Account"
  belongs_to :store_front, optional: true
  belongs_to :business, optional: true

  has_many :sales_orders, class_name: "StoreFrontModule::Orders::SalesOrder", dependent: :nullify
  has_many :orders, dependent: :nullify
  has_many :entries, class_name: "AccountingModule::Entry", dependent: :nullify
  has_many :vouchers, dependent: :nullify
  has_many :cash_counts, class_name: "CashCounts::CashCount", dependent: :nullify

  validates :employee_id, presence: true
  validates :cash_account_id, presence: true
  validates :session_date, presence: true, uniqueness: { scope: :employee_id }
  validate :only_one_open_session_per_employee, on: :create

  scope :for_day, ->(date) { where(session_date: date) }
  scope :recent, -> { order(session_date: :desc) }

  def cashier_name
    employee.try(:full_name)
  end

  def sales_total
    preloaded(sales_orders).sum(&:total_cost_less_discount)
  rescue StandardError
    0
  end

  def discounts_total
    preloaded(sales_orders).sum(&:discount_amount)
  rescue StandardError
    0
  end

  # Cash sales (paid immediately) vs credit sales (charged to customer).
  def cash_sales
    sales_orders.where(credit: [false, nil])
  end

  def credit_sales
    sales_orders.where(credit: true)
  end

  def credit_sales_total
    preloaded(credit_sales).sum(&:total_cost_less_discount)
  rescue StandardError
    0
  end

  # Transfers to/from other cash drawers or the proprietor: entries whose
  # commercial document is a User (remittances, cash transfers).
  def transfer_entries
    entries.where(commercial_document_type: "User").order(:entry_date)
  end

  def transfers_in_total
    scoped_debits_total(transfer_entries)
  end

  def transfers_out_total
    scoped_credits_total(transfer_entries)
  end

  CASH_RECEIPT_VOUCHER_TYPES = %w[
    Vouchers::CashSaleVoucher
    Vouchers::CreditSalesPaymentVoucher
    Vouchers::OtherSaleVoucher
    Vouchers::RepairPaymentVoucher
  ].freeze

  def cash_sale_vouchers
    vouchers.processed.where(type: "Vouchers::CashSaleVoucher").order(:date)
  end

  def credit_payment_vouchers
    vouchers.processed.where(type: "Vouchers::CreditSalesPaymentVoucher").order(:date)
  end

  def other_sale_vouchers
    vouchers.processed.where(type: "Vouchers::OtherSaleVoucher").order(:date)
  end

  def repair_payment_vouchers
    vouchers.processed.where(type: "Vouchers::RepairPaymentVoucher").order(:date)
  end

  # All money confirmed as received into the drawer this session: regular
  # POS sales, payments against existing credit sales, one-off "other sale"
  # cash receipts recorded outside the regular POS flow, and payments on
  # repair work orders — normalized into one merged, chronological list for
  # the Cash Receipts tab/report.
  def cash_receipts
    vouchers.processed.where(type: CASH_RECEIPT_VOUCHER_TYPES).order(:date).map do |voucher|
      {
        date: voucher.date,
        customer_name: voucher.payee_name,
        amount: voucher.payable_amount,
        kind: cash_receipt_kind(voucher),
        order: voucher.commercial_document,
      }
    end
  end

  def cash_receipts_total
    cash_receipts.sum { |row| row[:amount].to_d }
  end

  # Items sold in this session, aggregated by product name.
  # Returns [{ name:, quantity:, amount: }, ...] sorted by amount desc.
  def items_summary
    grouped = Hash.new { |hash, key| hash[key] = { name: key, quantity: 0, amount: BigDecimal("0"), bar_code: nil } }
    sales_orders.includes(sales_order_line_items: :product, other_sales_line_items: []).find_each do |order|
      order.sales_order_line_items.each do |line_item|
        key = line_item.product_name.presence || line_item.bar_code.presence || "Item"
        grouped[key][:quantity] += line_item.quantity.to_f
        grouped[key][:amount] += line_item.total_cost.to_d
        grouped[key][:bar_code] ||= line_item.bar_code.presence
      end
      order.other_sales_line_items.each do |line_item|
        key = line_item.description.presence || "Other Sale"
        grouped[key][:quantity] += 1
        grouped[key][:amount] += line_item.amount.to_d
      end
    end
    grouped.values.sort_by { |row| -row[:amount] }
  rescue StandardError
    []
  end

  def beginning_balance
    opening_system_amount || 0
  end

  def ending_balance
    closing_declared_amount.presence || expected_cash
  end

  # Cash movement scoped to this session. Falls back to date-range
  # scoping on the cash account for records created before sessions existed.
  def cash_debits_total
    session_entry_ids = entries.pluck(:id)
    if session_entry_ids.present?
      cash_account.debit_amounts.joins(:entry).where(entries: { id: session_entry_ids }).sum(:amount)
    else
      cash_account.debits_balance(from_date: session_date.beginning_of_day, to_date: session_date.end_of_day)
    end
  end

  def cash_credits_total
    session_entry_ids = entries.pluck(:id)
    if session_entry_ids.present?
      cash_account.credit_amounts.joins(:entry).where(entries: { id: session_entry_ids }).sum(:amount)
    else
      cash_account.credits_balance(from_date: session_date.beginning_of_day, to_date: session_date.end_of_day)
    end
  end

  def expected_cash
    (opening_system_amount || 0) + cash_debits_total - cash_credits_total
  end

  private

  # Order totals fan out to line_items, other_sales_line_items and
  # cash_payment per order — preload them so summaries stay flat
  # (a handful of queries) no matter how many sales the day holds.
  def preloaded(scope)
    scope.includes(:line_items, :sales_order_line_items, :other_sales_line_items, :cash_payment).to_a
  end

  def scoped_debits_total(entry_scope)
    ids = entry_scope.pluck(:id)
    return 0 if ids.blank?

    cash_account.debit_amounts.joins(:entry).where(entries: { id: ids }).sum(:amount)
  end

  def cash_receipt_kind(voucher)
    case voucher.type
    when "Vouchers::CashSaleVoucher" then "Cash Sale"
    when "Vouchers::CreditSalesPaymentVoucher" then "Credit Payment"
    when "Vouchers::OtherSaleVoucher" then "Other Sale"
    when "Vouchers::RepairPaymentVoucher" then "Repair Payment"
    end
  end

  def scoped_credits_total(entry_scope)
    ids = entry_scope.pluck(:id)
    return 0 if ids.blank?

    cash_account.credit_amounts.joins(:entry).where(entries: { id: ids }).sum(:amount)
  end

  def only_one_open_session_per_employee
    return unless open?
    return if session_date.blank? || employee_id.blank?

    if self.class.where(employee_id: employee_id, status: :open).where.not(session_date: session_date).exists?
      errors.add(:base, "Cashier already has an open session. Close it first.")
    end
  end
end
