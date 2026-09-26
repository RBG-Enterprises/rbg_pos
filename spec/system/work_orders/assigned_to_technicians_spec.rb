require 'rails_helper'
include ChosenSelect

describe 'Assigned To technician list on new work order' do
  it 'only offers active technicians from the current store front', js: true do
    proprietor      = create(:user, role: 'proprietor')
    customer        = create(:customer, business: proprietor.business)
    same_front_tech = create(:user, role: 'technician', first_name: 'Same', last_name: 'Front', store_front: proprietor.store_front)
    other_front_tech = create(:user, role: 'technician', first_name: 'Other', last_name: 'Front')
    deactivated_tech = create(:user, role: 'technician', first_name: 'Deactivated', last_name: 'Tech', store_front: proprietor.store_front, deactivated_at: Time.current)

    login_as(proprietor, scope: :user)
    visit new_computer_repair_section_work_order_path(customer_id: customer.id)

    technician_select = find('#work_orders_registration_technician_id', visible: false)
    expect(technician_select).to have_selector('option', text: 'Same Front', visible: false)
    expect(technician_select).not_to have_selector('option', text: 'Other Front', visible: false)
    expect(technician_select).not_to have_selector('option', text: 'Deactivated Tech', visible: false)
  end
end
