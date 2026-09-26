require 'rails_helper'

describe 'Accounts', type: :request do
  let(:clerk) do
    create(:sales_clerk, first_name: 'Ada', last_name: 'Lovelace',
      designation: 'Cashier')
  end

  before { login_as(clerk, scope: :user) }

  it 'shows details and the photo upload without the employee show page' do
    get account_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include(clerk.email)
    expect(response.body).to include('Sales Clerk')
    expect(response.body).to include('Cashier')
    expect(response.body).to include('employee-avatar-input')
    expect(response.body).to include('Change photo')
    expect(response.body).not_to include('Update Photo')
    expect(response.body).not_to include('Journal Entries')
  end

  it 'updates the photo' do
    old_blob_id = clerk.avatar.blob.id
    photo = fixture_file_upload(
      Rails.root.join('app', 'assets', 'images', 'default.png'), 'image/png')

    patch account_path, params: { user: { avatar: photo } }

    expect(response).to redirect_to(account_path)
    expect(clerk.reload.avatar.blob.id).not_to eq(old_blob_id)
  end
end
