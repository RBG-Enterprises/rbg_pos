require 'rails_helper'

describe 'Employee remittances', type: :request do
  def remittance_params(clerk:, proprietor:, cash:, destination:)
    {
      accounting_module_remittance_form: {
        recorder_id: proprietor.id,
        cashier_id: clerk.id,
        entry_date: Time.zone.now.to_s,
        reference_number: 'REF-1',
        description: 'Collection Remittance',
        amount: '1000',
        credit_account_id: cash.id,
        debit_account_id: destination.id
      }
    }
  end

  it 'shows a confirmation page before saving' do
    cash = create(:asset, name: 'Cash Confirm From')
    destination = create(:asset, name: 'Cash Confirm To')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    CashRegisterSessions::OpenForDay.call(employee: clerk)
    login_as(proprietor, scope: :user)

    post employee_remittances_path(clerk), params: remittance_params(
      clerk: clerk, proprietor: proprietor, cash: cash, destination: destination
    )

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Confirm Remittance')
    expect(response.body).to include('Cash Confirm To')
    expect(response.body).to include('Confirm Transfer')
    expect(AccountingModule::Entry.count).to eq 0
  end

  it 'saves on confirm and redirects to the session transfers pane' do
    cash = create(:asset, name: 'Cash Save From')
    destination = create(:asset, name: 'Cash Save To')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    login_as(proprietor, scope: :user)

    post employee_remittances_path(clerk), params: remittance_params(
      clerk: clerk, proprietor: proprietor, cash: cash, destination: destination
    ).deep_merge(confirmed: 'Confirm Transfer')

    expect(AccountingModule::Entry.count).to eq 1
    expect(response).to redirect_to("#{cash_register_session_path(session)}#transfers-pane")
  end

  it 'goes back to the form without saving' do
    cash = create(:asset, name: 'Cash Back From')
    destination = create(:asset, name: 'Cash Back To')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    proprietor = create(:proprietor)
    CashRegisterSessions::OpenForDay.call(employee: clerk)
    login_as(proprietor, scope: :user)

    post employee_remittances_path(clerk), params: remittance_params(
      clerk: clerk, proprietor: proprietor, cash: cash, destination: destination
    ).deep_merge(back: 'Back')

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Remittance Details')
    expect(response.body).to include('Save Remittance')
    expect(AccountingModule::Entry.count).to eq 0
  end
end
