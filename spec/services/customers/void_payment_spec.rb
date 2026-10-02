require 'rails_helper'

describe Customers::VoidPayment do
  def build_customer_payment(customer:, clerk:, cash:, amount: 100)
    AccountingModule::Entry.customer_credit_payment.create!(
      recorder: clerk, commercial_document: customer, entry_date: Time.zone.now,
      description: 'Customer payment', reference_number: SecureRandom.uuid,
      debit_amounts_attributes: [{ amount: amount, account: cash }],
      credit_amounts_attributes: [{ amount: amount, account: create(:asset) }]
    )
  end

  it 'posts a reversal entry that nets a customer-level payment to zero' do
    customer = create(:customer)
    proprietor = create(:proprietor)
    clerk = create(:sales_clerk)
    cash = create(:asset)
    clerk.update!(cash_on_hand_account: cash)
    payment = build_customer_payment(customer: customer, clerk: clerk, cash: cash)

    expect(customer.payment_entries.map(&:id)).to include(payment.id)

    void_entry = described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Duplicate payment")

    expect(void_entry).to be_persisted
    expect(void_entry.commercial_document).to eq customer
    expect(void_entry.description).to include("VOID of Entry ##{payment.id}")
    expect(void_entry.credit_amounts.map(&:account_id)).to eq payment.debit_amounts.map(&:account_id)
    expect(void_entry.debit_amounts.map(&:account_id)).to eq payment.credit_amounts.map(&:account_id)
    expect(payment.reload.voided?).to be true

    # Original shows as voided; reversal shows up in the account list too.
    reloaded = customer.reload.payment_entries
    expect(reloaded.map(&:id)).to include(payment.id, void_entry.id)
    expect(void_entry.void_entry?).to be true
  end

  it 'voids an order-keyed credit payment for the customer' do
    order = create(:sales_order, credit: true)
    customer = order.commercial_document
    proprietor = create(:proprietor)
    cash = create(:asset)
    order.employee.update!(cash_on_hand_account: cash)
    payment = AccountingModule::Entry.create!(
      recorder: order.employee, commercial_document: order, entry_date: Time.zone.now,
      description: 'Credit payment', reference_number: SecureRandom.uuid,
      debit_amounts_attributes: [{ amount: 50, account: cash }],
      credit_amounts_attributes: [{ amount: 50, account: order.receivable_account }]
    )

    void_entry = described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Duplicate payment")

    expect(void_entry).to be_persisted
    expect(customer.reload.payment_entries.map(&:id)).to include(payment.id, void_entry.id)
  end

  it 'keys the reversal to the customer when the payment has no document and lists it' do
    order = create(:sales_order, credit: true)
    customer = order.commercial_document
    proprietor = create(:proprietor)
    cash = create(:asset)
    order.employee.update!(cash_on_hand_account: cash)
    payment = AccountingModule::Entry.create!(
      recorder: order.employee, commercial_document: nil, entry_date: 3.days.ago,
      description: 'Legacy payment', reference_number: SecureRandom.uuid,
      debit_amounts_attributes: [{ amount: 40, account: cash }],
      credit_amounts_attributes: [{ amount: 40, account: order.receivable_account }]
    )

    void_entry = described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Duplicate payment")

    expect(void_entry.commercial_document).to eq customer
    expect(void_entry.entry_date.to_date).to eq Time.zone.today
    list = customer.reload.payment_entries.uniq.sort_by(&:entry_date).reverse
    expect(list.map(&:id)).to include(payment.id, void_entry.id)
    expect(list.first).to eq void_entry
  end

  it 'requires a void note saved on the reversal description' do
    customer = create(:customer)
    proprietor = create(:proprietor)
    clerk = create(:sales_clerk)
    cash = create(:asset)
    clerk.update!(cash_on_hand_account: cash)
    payment = build_customer_payment(customer: customer, clerk: clerk, cash: cash)

    expect {
      described_class.call(customer: customer, entry: payment, current_user: proprietor, note: " ")
    }.to raise_error(described_class::NotVoidable, /note/i)

    void_entry = described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Wrong amount entered")
    expect(void_entry.description).to include("Wrong amount entered")
    expect(payment.reload.voided?).to be true
  end

  it 'rejects non-proprietors, double voids, and foreign entries' do
    customer = create(:customer)
    proprietor = create(:proprietor)
    clerk = create(:sales_clerk)
    cash = create(:asset)
    clerk.update!(cash_on_hand_account: cash)
    payment = build_customer_payment(customer: customer, clerk: clerk, cash: cash)

    expect {
      described_class.call(customer: customer, entry: payment, current_user: clerk)
    }.to raise_error(described_class::NotVoidable, /proprietor/i)

    other_customer = create(:customer)
    expect {
      described_class.call(customer: other_customer, entry: payment, current_user: proprietor)
    }.to raise_error(described_class::NotVoidable, /belong/i)

    described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Test void")
    expect {
      described_class.call(customer: customer, entry: payment, current_user: proprietor, note: "Test void")
    }.to raise_error(described_class::NotVoidable, /already been voided/i)
  end
end
