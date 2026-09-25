class VoucherEntryCreation
  attr_reader :voucher, :cash_register_session

  def initialize(args)
    @voucher = args.fetch(:voucher)
    @cash_register_session = args[:cash_register_session]
  end

  def create_entry!
    entry = AccountingModule::Entry.new(
      recorder: voucher.preparer,
      commercial_document: voucher.payee,
      entry_date: voucher.date,
      description: voucher.description,
      cash_register_session: cash_register_session || order_session
    )
    voucher.voucher_amounts.debit.each do |amount|
      entry.debit_amounts.build(
      amount: amount.amount,
      account: amount.account
      )
    end

    voucher.voucher_amounts.credit.each do |amount|
      entry.credit_amounts.build(
      amount: amount.amount,
      account: amount.account
      )
    end
    entry.save!
    voucher.update!(entry: entry)
  end

  private

  def order_session
    commercial = voucher.commercial_document
    commercial.try(:cash_register_session)
  rescue StandardError
    nil
  end
end
