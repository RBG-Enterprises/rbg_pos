require 'rails_helper'

describe 'Sign in', type: :request do
  it 'renders the sign in page' do
    get new_user_session_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Sign in to continue')
    expect(response.body).to include('user_email')
    expect(response.body).to include('user_password')
  end
end
