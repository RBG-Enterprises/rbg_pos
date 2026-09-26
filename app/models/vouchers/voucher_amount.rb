module Vouchers
  class VoucherAmount < ApplicationRecord
    enum :amount_type, [:debit, :credit]
    belongs_to :account, class_name: "AccountingModule::Account"
    belongs_to :voucher, optional: true
    belongs_to :cart, optional: true

    belongs_to :commercial_document, polymorphic: true, optional: true
    belongs_to :recorder, class_name: "User", optional: true
    delegate :name, to: :account, prefix: true

    def self.without_voucher
      where(voucher_id: nil)
    end

    def self.total
      sum(:amount)
    end
  end
end
