# frozen_string_literal: true

require "rails_helper"

describe Vouchers::Cancellation do
  let!(:entry) { create(:entry_with_credit_and_debit) }
  let!(:voucher) { create(:voucher, entry: entry) }

  before { described_class.run(voucher: voucher) }

  it { expect(Voucher.find_by(id: voucher&.id)).to be_nil }
  it { expect(AccountingModule::Entry.find_by(id: entry&.id)).to be_nil }
end
