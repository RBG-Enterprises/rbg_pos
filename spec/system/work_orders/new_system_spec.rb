require 'rails_helper'
include ChosenSelect

describe 'New work order' do
  before(:each) do
    work_order = create(:work_order)
    supplier   = create(:supplier, business_name: 'Test supplier')
    category   = create(:work_order_category, title: 'Desktop')
    user       = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')
    @customer  = create(:customer, first_name: 'Juan', last_name: 'Cruz', business: user.business)

    login_as(user, scope: :user)
    visit computer_repair_section_dashboard_index_path
    click_link 'New Repair'
  end
  it 'with valid attributes', js: true do
    fill_in "customer-search-form", with: @customer.full_name
    click_button "customer-search-btn"
    click_link "#{@customer.id}-select-customer"
    select_from_chosen 'Test Tech', from: 'Assigned To'
    select_from_chosen 'Desktop', from: 'Category'

    fill_in 'Contact person',           with: 'none'
    fill_in 'Manufacturer/Description', with: 'Asus'
    fill_in 'Model number',             with: 'XYZ'
    fill_in 'Serial number',            with: '4234243'
    fill_in 'Physical condition',       with: 'good'
    fill_in 'Reported problem',         with: 'no power'
    check 'Under warranty'
    fill_in 'supplier-search', with: 'Test supplier'
    within('.typeahead-menu') { click_on 'Test supplier' }
    fill_in 'Purchase date',            with: Date.current.strftime("%B %e, %Y")
    fill_in 'Expiry date',              with: Date.current.next_year

    click_button 'Save Work Order'

    expect(page).to have_content('received successfully')

  end
end
