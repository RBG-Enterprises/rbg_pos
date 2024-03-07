module Vouchers
  class Confirmation
    attr_reader :voucher
    def initialize(voucher:)
      @voucher = voucher
    end
    def confirm!
      entry = AccountingModule::Entry.new(
        recorder: voucher.preparer,
        entry_date: voucher.date,
        reference_number: voucher.reference_number,
        description: voucher.description
      )
      voucher.voucher_amounts.debit.each do |amount|
        entry.debit_amounts.build(
          amount: amount.amount,
          account: amount.account,
          entry: entry
        )
      end
      voucher.voucher_amounts.credit.each do |amount|
        entry.credit_amounts.build(
          amount: amount.amount,
          account: amount.account,
          entry: entry
        )
      end
      entry.save!
    end
  end
end
