class Voucher < ApplicationRecord
  belongs_to :payee,               polymorphic: true
  belongs_to :commercial_document, polymorphic: true, optional: true
  belongs_to :preparer,            class_name: "User", optional: true
  belongs_to :entry,    class_name: 'AccountingModule::Entry', foreign_key: 'entry_id', optional: true
  has_many :voucher_amounts,       class_name: "Vouchers::VoucherAmount", dependent: :destroy
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
    where(payee_type: 'Supplier')
  end

  def self.disbursed
    where.not(entry_id: nil)
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
