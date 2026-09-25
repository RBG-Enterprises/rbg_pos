require 'rails_helper'

describe CashRegisterSession do
  describe 'associations' do
    it { is_expected.to belong_to :employee }
    it { is_expected.to belong_to :cash_account }
    it { is_expected.to have_many :sales_orders }
    it { is_expected.to have_many :entries }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :employee_id }
    it { is_expected.to validate_presence_of :cash_account_id }
    it { is_expected.to validate_presence_of :session_date }
  end
end

describe CashRegisterSessions::OpenForDay do
  it 'opens one session per cashier per day and resumes on second call' do
    cash = create(:asset, name: 'Cash on Hand Test')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    first = described_class.call(employee: clerk, date: Date.current)
    second = described_class.call(employee: clerk, date: Date.current)
    expect(first).to be_persisted
    expect(second.id).to eq first.id
    expect(clerk.cash_register_sessions.for_day(Date.current).count).to eq 1
  end

  it 'does not open sessions for users without a cash-on-hand account' do
    proprietor = create(:proprietor)
    expect(proprietor.cashier?).to be false
    expect(described_class.call(employee: proprietor)).to be_nil
  end

  it 'opens a session for any role with a cash-on-hand account' do
    cash = create(:asset, name: 'Cash on Hand Technician')
    technician = create(:technician, cash_on_hand_account: cash)
    expect(technician.cashier?).to be true
    expect(described_class.call(employee: technician)).to be_persisted
  end

  it 'auto-closes stale sessions when opening a new day' do
    cash = create(:asset, name: 'Cash on Hand Stale')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    stale = described_class.call(employee: clerk, date: Date.current - 1.day)
    expect(stale).to be_open
    fresh = described_class.call(employee: clerk, date: Date.current)
    expect(fresh).to be_open
    expect(stale.reload).to be_closed
  end
end

describe CashRegisterSessions::CloseSession do
  it 'closes with variance' do
    cash = create(:asset, name: 'Cash on Hand Close')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    session.update!(opening_system_amount: 1000)
    described_class.call(session: session, counted_amount: 1200)
    session.reload
    expect(session).to be_closed
    expect(session.closing_declared_amount.to_f).to eq 1200
    expect(session.closing_system_amount.to_f).to eq session.expected_cash.to_f
  end
end

describe 'CashRegisterSession EOD report' do  it 'renders a PDF with cash summary, items, credit sales and transfers' do
    cash = create(:asset, name: 'Cash on Hand EOD PDF')
    other_cash = create(:asset, name: 'Cash on Hand EOD Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    session.update!(opening_system_amount: 1000)

    cash_order = create(:sales_order, employee: clerk, store_front: clerk.store_front,
                                      cash_register_session: session, date: Time.zone.now)
    create(:sales_order_line_item, order: cash_order, quantity: 2, total_cost: 200)
    credit_order = create(:sales_order, employee: clerk, store_front: clerk.store_front,
                                        cash_register_session: session, credit: true, date: Time.zone.now)
    create(:sales_order_line_item, order: credit_order, quantity: 1, total_cost: 150)
    AccountingModule::Entry.create!(
      recorder: clerk, commercial_document: clerk, entry_date: Time.zone.now,
      description: 'Cash transfer in', cash_register_session: session,
      debit_amounts_attributes: [{ amount: 500, account: cash }],
      credit_amounts_attributes: [{ amount: 500, account: other_cash }]
    )
    CashRegisterSessions::CloseSession.call(session: session.reload, counted_amount: 1700)

    helper = Object.new
    def helper.number_to_currency(number, options = {})
      ActionController::Base.helpers.number_to_currency(number, options)
    end
    pdf = Reports::CashRegisterSessionPdf.new(
      cash_register_session: session.reload, business: clerk.business, view_context: helper
    )
    reader = PDF::Reader.new(StringIO.new(pdf.render))
    text = reader.pages.map(&:text).join("\n")
    expect(text).to include('END OF DAY REPORT')
    expect(text).to include('BEGINNING BALANCE')
    expect(text).to include('CASH RECEIVED')
    expect(text).to include('CREDIT SALES')
    expect(text).to include('TRANSFERS')
    expect(text).to include('ITEMS SOLD')
    expect(text).to include('ENDING BALANCE')
  end
end

describe 'CashRegisterSession report breakdowns' do
  it 'separates cash sales from credit sales and summarizes items' do
    cash = create(:asset, name: 'Cash on Hand Breakdown')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)

    cash_order = create(:sales_order, employee: clerk, store_front: clerk.store_front,
                                      cash_register_session: session, date: Time.zone.now)
    create(:sales_order_line_item, order: cash_order, quantity: 2, total_cost: 200)
    credit_order = create(:sales_order, employee: clerk, store_front: clerk.store_front,
                                        cash_register_session: session, credit: true, date: Time.zone.now)
    create(:sales_order_line_item, order: credit_order, quantity: 1, total_cost: 150)

    expect(session.cash_sales.count).to eq 1
    expect(session.credit_sales.count).to eq 1
    expect(session.cash_sales_total).to eq 200
    expect(session.credit_sales_total).to eq 150
    expect(session.items_summary.map { |row| row[:amount].to_f }.sum).to eq 350
  end

  it 'scopes transfers and exposes beginning and ending balances' do
    cash = create(:asset, name: 'Cash on Hand Transfers')
    other_cash = create(:asset, name: 'Cash on Hand Other')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    session.update!(opening_system_amount: 1000, closing_declared_amount: 1600)

    AccountingModule::Entry.create!(
      recorder: clerk, commercial_document: clerk, entry_date: Time.zone.now,
      description: 'Cash transfer in', cash_register_session: session,
      debit_amounts_attributes: [{ amount: 500, account: cash }],
      credit_amounts_attributes: [{ amount: 500, account: other_cash }]
    )

    expect(session.transfer_entries.count).to eq 1
    expect(session.transfers_in_total).to eq 500
    expect(session.transfers_out_total).to eq 0
    expect(session.beginning_balance).to eq 1000
    expect(session.ending_balance).to eq 1600
  end
end

describe 'CashRegisterSession query volume' do
  it 'summarizes a session in a bounded number of queries regardless of order count' do
    cash = create(:asset, name: 'Cash on Hand Query Bound')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    12.times do
      order = create(:sales_order, employee: clerk, store_front: clerk.store_front,
                                   cash_register_session: session, date: Time.zone.now)
      create(:sales_order_line_item, order: order, quantity: 2, total_cost: 200)
    end

    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      query_count += 1 unless payload[:name] == 'SCHEMA'
    end
    session.cash_sales_total
    session.credit_sales_total
    session.sales_total
    session.discounts_total
    session.items_summary
    session.cash_debits_total
    session.cash_credits_total
    session.expected_cash
    ActiveSupport::Notifications.unsubscribe(subscriber)

    expect(query_count).to be < 40
  end
end
