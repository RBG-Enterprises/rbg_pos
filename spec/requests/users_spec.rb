require 'rails_helper'

describe 'Users', type: :request do
  let(:proprietor) { create(:proprietor) }

  before { login_as(proprietor, scope: :user) }

  describe 'GET /users/:id/edit' do
    it 'renders a cash account typeahead instead of loading every asset' do
      cash = create(:asset, name: 'Petty Cash Drawer', business: proprietor.business)
      other = create(:asset, name: 'Unrelated Vault Account', business: proprietor.business)
      employee = create(:sales_clerk, business: proprietor.business,
        store_front: proprietor.store_front, cash_on_hand_account: cash)

      get edit_user_path(employee)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('cash-account-typeahead')
      # current account shown as the selected chip...
      expect(response.body).to include('Petty Cash Drawer')
      # ...but the rest of the chart of accounts is not rendered into the page
      expect(response.body).not_to include('Unrelated Vault Account')
    end
  end

  describe 'PATCH /users/:id' do
    it 'still updates the cash on hand account from the hidden field' do
      old_cash = create(:asset, name: 'Old Drawer', business: proprietor.business)
      new_cash = create(:asset, name: 'New Drawer', business: proprietor.business)
      employee = create(:sales_clerk, business: proprietor.business,
        store_front: proprietor.store_front, cash_on_hand_account: old_cash)

      patch user_path(employee),
        params: { user: { cash_on_hand_account_id: new_cash.id } }

      expect(employee.reload.cash_on_hand_account).to eq(new_cash)
    end
  end

  describe 'GET /accounting/accounts.json' do
    it 'searches asset accounts by name prefix' do
      create(:asset, name: 'Cash Drawer A', business: proprietor.business)
      create(:asset, name: 'Cash Drawer B', business: proprietor.business)
      create(:asset, name: 'Bank Vault', business: proprietor.business)

      get accounting_accounts_path, params: { search: 'Cash Drawer' }, as: :json

      expect(response).to have_http_status(:success)
      texts = JSON.parse(response.body).map { |r| r['text'] }
      expect(texts.grep(/Cash Drawer A/)).not_to be_empty
      expect(texts.grep(/Cash Drawer B/)).not_to be_empty
      expect(texts.grep(/Bank Vault/)).to be_empty
    end

    it 'caps results at 20' do
      21.times { |n| create(:asset, name: "Drawer #{n}", business: proprietor.business) }

      get accounting_accounts_path, params: { search: 'Drawer' }, as: :json

      expect(JSON.parse(response.body).size).to eq(20)
    end
  end
end
