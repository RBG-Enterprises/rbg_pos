require 'rails_helper'

describe 'Department and Supplier typeahead on new work order' do
  before(:each) do
    user = create(:user, role: 'technician', first_name: 'Test', last_name: 'Tech')
    customer = create(:customer, first_name: 'Juan', last_name: 'Cruz', business: user.business)
    @department = create(:department, name: 'IT Department', customer: customer)
    @supplier   = create(:supplier, business_name: 'Acme Supplies')

    login_as(user, scope: :user)
    visit new_computer_repair_section_work_order_path(customer_id: customer.id)
  end

  it 'finds and selects a department without a full page dropdown', js: true do
    fill_in 'department-search', with: 'IT Depart'

    within('.typeahead-menu') do
      expect(page).to have_content('IT Department')
      click_on "#{@department.customer.name} - #{@department.name}"
    end

    expect(page).to have_content("#{@department.customer.name} - #{@department.name}")
    expect(find('#work_orders_registration_department_id', visible: false).value).to eq(@department.id.to_s)
  end

  it 'finds and selects a supplier once under warranty is checked', js: true do
    check 'Under warranty'
    fill_in 'supplier-search', with: 'Acme'

    within('.typeahead-menu') do
      expect(page).to have_content('Acme Supplies')
      click_on 'Acme Supplies'
    end

    expect(page).to have_content('Acme Supplies')
    expect(find('#work_orders_registration_supplier_id', visible: false).value).to eq(@supplier.id.to_s)
  end

  it 'shows a no-results message when the department search has no match', js: true do
    fill_in 'department-search', with: 'Nonexistent Department'

    within('.typeahead-menu') do
      expect(page).to have_content('No results found for "Nonexistent Department"')
    end
  end

  it 'shows a no-results message when the supplier search has no match', js: true do
    check 'Under warranty'
    fill_in 'supplier-search', with: 'Nonexistent Supplier'

    within('.typeahead-menu') do
      expect(page).to have_content('No results found for "Nonexistent Supplier"')
    end
  end
end
