require 'rails_helper'

describe 'Store front switching', type: :request do
  let(:business) { create(:business) }
  let(:home) { create(:store_front, business: business, name: 'Home Branch') }
  let(:other) { create(:store_front, business: business, name: 'Other Branch') }
  let(:clerk) { create(:sales_clerk, business: business, store_front: home) }

  it 'lists the switchable store fronts in the navbar' do
    clerk.user_store_fronts.create!(store_front: other)
    login_as(clerk, scope: :user)

    get employees_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Home Branch')
    expect(response.body).to include('Other Branch')
  end

  it 'shows a Switch Store section with all store fronts in the user dropdown' do
    clerk.user_store_fronts.create!(store_front: other)
    login_as(clerk, scope: :user)

    get employees_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Switch store')
    expect(response.body).to include('switch-store-list')
    expect(response.body).to include(
      store_front_switches_path(store_front_id: other.id))
    expect(response.body).to include(account_path)
  end

  it 'shows the current user avatar beside their name in the navbar' do
    login_as(clerk, scope: :user)

    get employees_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include(clerk.first_name)
    expect(response.body).to include(clerk.avatar.signed_id)
  end

  it 'switches the current store front to a granted one' do
    clerk.user_store_fronts.create!(store_front: other)
    login_as(clerk, scope: :user)

    post store_front_switches_path(store_front_id: other.id),
      headers: { "HTTP_REFERER" => employees_path }

    expect(response).to redirect_to(employees_path)
    follow_redirect!
    expect(response.body).to include('Other Branch')
  end

  it 'refuses to switch to a store front without access' do
    login_as(clerk, scope: :user)

    post store_front_switches_path(store_front_id: other.id),
      headers: { "HTTP_REFERER" => employees_path }

    expect(response).to redirect_to(employees_path)
    follow_redirect!
    expect(response.body).to include('Home Branch')
  end

  it 'lets a proprietor grant and revoke store front access' do
    proprietor = create(:proprietor, business: business, store_front: home)
    login_as(proprietor, scope: :user)

    post employee_store_front_accesses_path(clerk),
      params: { store_front_access: { store_front_id: other.id } }
    expect(response).to redirect_to(employee_settings_path(clerk))
    expect(clerk.reload.switchable_store_fronts).to include(other)

    access = clerk.user_store_fronts.find_by!(store_front: other)
    delete employee_store_front_access_path(clerk, access)
    expect(response).to redirect_to(employee_settings_path(clerk))
    expect(clerk.reload.switchable_store_fronts).not_to include(other)
  end

  it 'forbids non-proprietors from granting store front access' do
    login_as(clerk, scope: :user)

    post employee_store_front_accesses_path(clerk),
      params: { store_front_access: { store_front_id: other.id } }

    expect(clerk.reload.switchable_store_fronts).not_to include(other)
  end
end
