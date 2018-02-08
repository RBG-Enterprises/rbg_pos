class OtherSalesForm
  include ActiveModel::Model
  attr_accessor :description, :reference_number, :recorder_id, :amount, :date, :customer_id
  validates :amount, :description, :customer_id, :date, presence: true

  def save
    ActiveRecord::Base.transaction do
      save_other_sales
      create_order
    end
  end

  private
  def save_other_sales
    AccountingModule::Entry.other_sale.create!(recorder_id: recorder_id, entry_date: date, reference_number: reference_number, description: description,
      credit_amounts_attributes: [amount: amount, account: credit_account,commercial_document: find_customer],
      debit_amounts_attributes: [amount: amount, account: debit_account, commercial_document: find_customer])
  end
  def credit_account
    AccountingModule::Account.find_by(name: "Other Income")
  end
  def debit_account
    User.find_by(id: recorder_id).default_cash_on_hand_account
  end
  def create_order
    order = Order.create!(description: description, customer_id: customer_id, date: date, employee_id: recorder_id, reference_number: reference_number)
    Payment.create(mode_of_payment: 'cash', order: order, total_cost: amount)
  end
  def find_customer
    Customer.find_by_id(customer_id)
  end

end
