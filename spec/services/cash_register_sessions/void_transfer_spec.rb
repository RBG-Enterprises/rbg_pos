require 'rails_helper'

describe CashRegisterSessions::VoidTransfer do
  def build_transfer(cash:, other_cash:, clerk:, session:, description: 'Cash transfer in', entry_date: Time.zone.now)
    AccountingModule::Entry.create!(
      recorder: clerk, commercial_document: clerk, entry_date: entry_date,
      description: description, cash_register_session: session,
      debit_amounts_attributes: [{ amount: 500, account: cash }],
      credit_amounts_attributes: [{ amount: 500, account: other_cash }]
    )
  end

  it 'posts a contra entry that nets the transfer to zero in the same session' do
    cash = create(:asset, name: 'Cash on Hand Void')
    other_cash = create(:asset, name: 'Cash on Hand Void Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    transfer = build_transfer(cash: cash, other_cash: other_cash, clerk: clerk, session: session)

    expect(session.transfers_in_total).to eq 500

    void_entry = described_class.call(entry: transfer, current_user: proprietor)

    expect(void_entry).to be_persisted
    expect(void_entry.cash_register_session_id).to eq session.id
    expect(void_entry.description).to include("VOID of Entry ##{transfer.id}")
    expect(void_entry.credit_amounts.map(&:account_id)).to eq transfer.debit_amounts.map(&:account_id)
    expect(void_entry.debit_amounts.map(&:account_id)).to eq transfer.credit_amounts.map(&:account_id)
    expect(session.reload.transfers_in_total - session.cash_credits_total).to eq 0
    expect(transfer.reload.voided?).to be true
  end

  it 'rejects non-proprietors' do
    cash = create(:asset, name: 'Cash on Hand Void Clerk')
    other_cash = create(:asset, name: 'Cash on Hand Void Clerk Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    other_clerk = create(:sales_clerk)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    transfer = build_transfer(cash: cash, other_cash: other_cash, clerk: clerk, session: session)

    expect {
      described_class.call(entry: transfer, current_user: other_clerk)
    }.to raise_error(described_class::NotVoidable, /proprietor/i)
  end

  it 'rejects transfers not made today' do
    cash = create(:asset, name: 'Cash on Hand Void Old')
    other_cash = create(:asset, name: 'Cash on Hand Void Old Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    transfer = build_transfer(
      cash: cash, other_cash: other_cash, clerk: clerk, session: session,
      entry_date: 2.days.ago
    )

    expect {
      described_class.call(entry: transfer, current_user: proprietor)
    }.to raise_error(described_class::NotVoidable, /today/i)
  end

  it 'rejects non-transfer entries and double voids' do
    cash = create(:asset, name: 'Cash on Hand Void Guard')
    other_cash = create(:asset, name: 'Cash on Hand Void Guard Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    customer = create(:customer)

    non_transfer = AccountingModule::Entry.create!(
      recorder: clerk, commercial_document: customer, entry_date: Time.zone.now,
      description: 'Cash sale', cash_register_session: session,
      debit_amounts_attributes: [{ amount: 100, account: cash }],
      credit_amounts_attributes: [{ amount: 100, account: other_cash }]
    )
    expect {
      described_class.call(entry: non_transfer, current_user: proprietor)
    }.to raise_error(described_class::NotVoidable, /transfer/i)

    transfer = build_transfer(cash: cash, other_cash: other_cash, clerk: clerk, session: session)
    described_class.call(entry: transfer, current_user: proprietor)
    expect {
      described_class.call(entry: transfer, current_user: proprietor)
    }.to raise_error(described_class::NotVoidable, /already been voided/i)
  end
end
