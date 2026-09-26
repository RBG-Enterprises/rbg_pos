require 'rails_helper'

describe 'Customer search typeahead on new work order' do
  it 'shows matching customers as you type, without a full page reload', js: true do
    user = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')
    customer = create(:customer, first_name: 'Juan', last_name: 'Cruz', business: user.business)

    login_as(user, scope: :user)
    visit new_computer_repair_section_work_order_path

    fill_in 'customer-search-form', with: 'Juan Cruz'

    within('#customer-search-results') do
      expect(page).to have_link("#{customer.id}-select-customer")
    end

    click_link "#{customer.id}-select-customer"
    expect(page).to have_content('Change Customer')
  end

  it 'shows a no-results message when the search has no match', js: true do
    user = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')

    login_as(user, scope: :user)
    visit new_computer_repair_section_work_order_path

    fill_in 'customer-search-form', with: 'Nonexistent Customer'

    within('#customer-search-results') do
      expect(page).to have_content('No customers found for')
      expect(page).to have_content('Nonexistent Customer')
    end
  end
end
