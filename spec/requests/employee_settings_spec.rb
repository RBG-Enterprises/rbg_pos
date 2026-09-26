require 'rails_helper'

describe 'Employee settings', type: :request do
  let(:clerk) { create(:sales_clerk) }

  before { login_as(clerk, scope: :user) }

  it 'shows the photo upload form to the employee on their own settings page' do
    get employee_settings_path(clerk)

    expect(response).to have_http_status(:success)
    expect(response.body).to include('employee-avatar-input')
  end

  it 'lets an employee update their own photo' do
    photo = fixture_file_upload(
      Rails.root.join('app', 'assets', 'images', 'default.png'), 'image/png')

    patch employee_path(clerk), params: { user: { avatar: photo } }

    expect(response).to redirect_to(employee_settings_path(clerk))
  end

  it 'forbids updating another employee photo' do
    other = create(:sales_clerk)
    photo = fixture_file_upload(
      Rails.root.join('app', 'assets', 'images', 'default.png'), 'image/png')

    patch employee_path(other), params: { user: { avatar: photo } }

    expect(response).to redirect_to(customers_url)
  end

  it 'still lets a proprietor update any employee photo' do
    proprietor = create(:proprietor)
    login_as(proprietor, scope: :user)
    photo = fixture_file_upload(
      Rails.root.join('app', 'assets', 'images', 'default.png'), 'image/png')

    patch employee_path(clerk), params: { user: { avatar: photo } }

    expect(response).to redirect_to(employee_settings_path(clerk))
  end
end
