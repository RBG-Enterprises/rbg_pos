require 'rails_helper'

describe 'Cash register sessions', type: :request do
  it 'shows a Transfer link to the cashier on an open session' do
    cash = create(:asset, name: 'Cash Transfer Link')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    login_as(clerk, scope: :user)

    get cash_register_session_path(session)

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Transfer')
    expect(response.body).to include(
      new_employee_remittance_path(employee_id: clerk.id, cash_account_id: cash.id)
    )
  end

  it 'hides the Transfer link on a closed session' do
    cash = create(:asset, name: 'Cash Transfer Link Closed')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    CashRegisterSessions::CloseSession.call(session: session.reload, counted_amount: 100)
    login_as(clerk, scope: :user)

    get cash_register_session_path(session)

    expect(response).to have_http_status(:success)
    expect(response.body).not_to include(
      new_employee_remittance_path(employee_id: clerk.id, cash_account_id: cash.id)
    )
  end

  it 'renders the sessions index and store banner' do
    cash = create(:asset, name: 'Cash Banner Link')
    clerk = create(:sales_clerk, cash_on_hand_account: cash)
    CashRegisterSessions::OpenForDay.call(employee: clerk)
    login_as(clerk, scope: :user)

    get cash_register_sessions_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Cash Sessions')

    get store_index_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Opening float')
  end

  it 'lets a proprietor filter sessions by cashier and date' do
    cash = create(:asset, name: 'Cash Filter Link')
    clerk = create(:sales_clerk, first_name: 'Ada', last_name: 'Lovelace', cash_on_hand_account: cash)
    session = CashRegisterSessions::OpenForDay.call(employee: clerk)
    proprietor = create(:proprietor)
    login_as(proprietor, scope: :user)

    get cash_register_sessions_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include('cash-sessions-cashier-search')

    get cash_register_sessions_path(employee_id: clerk.id, date: session.session_date)
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Ada Lovelace')
  end

  it 'returns matching cashiers for the typeahead search' do
    cash = create(:asset, name: 'Cash Typeahead Link')
    clerk = create(:sales_clerk, first_name: 'Grace', last_name: 'Hopper', cash_on_hand_account: cash)
    CashRegisterSessions::OpenForDay.call(employee: clerk)
    proprietor = create(:proprietor)
    login_as(proprietor, scope: :user)

    get cash_register_sessions_path(cashier_search: 'Grace'), xhr: true, as: :js

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Grace Hopper')
  end
end
