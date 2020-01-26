require 'rails_helper'
include ChosenSelect

describe 'New work order' do
  before(:each) do
    work_order = create(:work_order)
    supplier   = create(:supplier, business_name: 'Test supplier')
    category   = create(:work_order_category, title: 'Desktop')
    customer   = create(:customer, first_name: 'Juan', last_name: 'Cruz')
    user       = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')
    login_as(user, scope: :user)
    visit computer_repair_section_dashboard_index_path
    click_link 'New Repair'
  end
  it 'with valid attributes', js: true do
    select_from_chosen 'Test Tech', from: 'Assigned To'
    select_from_chosen 'Desktop', from: 'Category'
    fill_in 'Date received',            with: Date.current
    select_from_chosen 'Juan Cruz', from: 'Customer'
    fill_in 'Contact person',           with: 'none'
    fill_in 'Manufacturer/Description', with: 'Asus'
    fill_in 'Model number',             with: 'XYZ'
    fill_in 'Serial number',            with: '4234243'
    fill_in 'Physical condition',       with: 'good'
    fill_in 'Reported problem',         with: 'no power'
    check 'Under warranty'
    select_from_chosen 'Test supplier', from: 'Supplier'
    fill_in 'Purchase date',            with: Date.current
    fill_in 'Expiry date',              with: Date.current.next_year

    click_button 'Save Work Order'

    expect(page).to have_content('received successfully')

  end

  it 'with invalid attributes' do
    click_button 'Save Work Order'

    expect(page).to have_content("can't be blank")
  end
end