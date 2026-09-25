class OtherSalesForm
  include ActiveModel::Model
  attr_accessor :description, :reference_number, :recorder_id, :amount, :date, :customer_id, :account_number, :sales_order_id, :cash_register_session_id
  validates :amount, :description, :customer_id, :date, presence: true

  def find_order
    StoreFrontModule::Orders::SalesOrder.find_by(account_number: account_number)
  end

  def process!
    ActiveRecord::Base.transaction do
      create_order
    end
  end

  private
  def create_order
    order = StoreFrontModule::Orders::SalesOrder.create!(
      description: description,
      commercial_document: find_customer,
      date: date,
      employee_id: recorder_id,
      reference_number: reference_number,
      store_front: find_employee.store_front,
      account_number: account_number,
      cash_register_session_id: cash_register_session_id)
      create_accounts(order)
      order.save!
    order.create_cash_payment(cash_tendered: amount)
  end


  def find_customer
    Customer.find(customer_id)
  end

  def find_employee
    User.find(recorder_id)
  end


  def create_accounts(order)
    AccountCreators::SalesOrder.new(sales_order: order).create_accounts!
  end

end
