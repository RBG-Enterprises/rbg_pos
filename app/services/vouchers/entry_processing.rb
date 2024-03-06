module Vouchers
  class EntryProcessing
    attr_reader :voucher

    def initialize(voucher:)
      @voucher = voucher
    end

    def create_entry!
      entry = AccountingModule::Entry.new(
        entry_date: voucher.date,
        reference_number: voucher.reference_number,
        description: voucher.description,
        commercial_document: voucher.commercial_document,
        recorder: voucher.preparer)
      voucher.voucher_amounts.debit.each do |amount|
        entry.debit_amounts.build(
          amount: amount.amount,
          account: amount.account)
      end
      voucher.voucher_amounts.credit.each do |amount|
        entry.credit_amounts.build(
          amount: amount.amount,
          account: amount.account)
      end
      entry.save!
      voucher.update!(entry_id: entry.id)
    end
  end
end
