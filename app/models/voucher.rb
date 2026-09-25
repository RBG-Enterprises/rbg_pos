# frozen_string_literal: true

class Voucher < ApplicationRecord
  belongs_to :payee,               polymorphic: true
  belongs_to :commercial_document, polymorphic: true, optional: true
  belongs_to :preparer,            class_name: "User", optional: true
  belongs_to :entry,                 class_name: "AccountingModule::Entry", optional: true
  belongs_to :cash_register_session, optional: true
  has_many :voucher_amounts,         class_name: "Vouchers::VoucherAmount", dependent: :destroy
  has_many :orders, dependent: :destroy
  delegate :name, to: :preparer, prefix: true, allow_nil: true
  delegate :name, to: :disburser, prefix: true, allow_nil: true
  delegate :name, to: :payee, prefix: true, allow_nil: true
  delegate :total, to: :entry, allow_nil: true

  validates :account_number, presence: true, uniqueness: true

  def self.unused
    where(entry_id: nil)
  end

  def self.for_suppliers
    where(payee_type: "Supplier")
  end

  def self.disbursed
    where.not(entry_id: nil)
  end

  def self.processed
    where.not(entry_id: nil)
  end

  # Voucher-creating forms only collect a calendar date (a plain datepicker,
  # no time field), so a naive assignment stores midnight and every voucher
  # shows the same wrong "12:00 AM" time everywhere it's displayed. Keep the
  # chosen date but stamp it with the actual time the voucher is recorded.
  def self.transaction_time_for(date_value)
    base_date = date_value.presence && date_value.to_date || Date.current
    Time.zone.now.change(year: base_date.year, month: base_date.month, day: base_date.day)
  rescue ArgumentError, TypeError
    Time.zone.now
  end

  def payable_amount
    voucher_amounts.debit.total
  end

  def disbursed?
    entry.present?
  end

  def disburser
    entry.recorder
  end

  def unused?
    !disbursed?
  end

  def disbursement_status
    if !disbursed?
      "Pending"
    else
      "Disbursed"
    end
  end
end
