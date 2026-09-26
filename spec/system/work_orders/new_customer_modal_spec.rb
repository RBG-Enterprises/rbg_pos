require 'rails_helper'

describe 'New Customer modal on new work order' do
  before(:each) do
    user = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')
    login_as(user, scope: :user)
    visit new_computer_repair_section_work_order_path
    click_link 'New Customer'
  end

  it 'creates the customer without leaving the page and selects them', js: true do
    within('#customer-modal') do
      fill_in 'First name', with: 'Juan'
      fill_in 'Last name', with: 'Cruz'
      fill_in 'Address', with: 'test address'
      fill_in 'Contact number', with: 'test number'

      click_button 'Save Customer'
    end

    expect(page).to have_content('Change Customer')
    expect(page).to have_content(/juan cruz/i)
  end

  it 'shows validation errors inside the modal', js: true do
    within('#customer-modal') do
      click_button 'Save Customer'

      expect(page).to have_content("can't be blank")
    end
  end
end
