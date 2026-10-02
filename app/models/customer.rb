class Customer < ApplicationRecord
	include PgSearch::Model
  has_one_attached :avatar
	pg_search_scope :text_search, against: [:first_name, :last_name, :contact_number, :address]
  multisearchable against: [:first_name, :last_name]

  belongs_to :business
  belongs_to :receivable_account,      class_name: 'AccountingModule::Account', optional: true
  belongs_to :sales_revenue_account,   class_name: 'AccountingModule::Account', optional: true
  belongs_to :sales_discount_account,  class_name: 'AccountingModule::Account', optional: true
  belongs_to :service_revenue_account, class_name: 'AccountingModule::Account', optional: true

	has_many :orders, as: :commercial_document, class_name: 'StoreFrontModule::Orders::SalesOrder'
	has_many :entries, through: :orders
  has_many :payments, as: :commercial_document, class_name: "AccountingModule::Entry"
	has_many :line_items, through: :orders
  has_many :work_orders
  has_many :departments, dependent: :nullify
  has_many :sales_orders, class_name: "StoreFrontModule::Orders::SalesOrder", as: :commercial_document

  before_validation :normalize_name

  validates :first_name, :last_name, :contact_number, presence: true
  validates :first_name, uniqueness: {
    scope: :last_name,
    case_sensitive: false,
    message: "customer already exists"
  }
  scope :recent, ->(num) { order('created_at DESC').limit(num) }
  before_validation :set_account_number
  before_save :set_default_image



  def self.receivable_accounts
    ids = pluck(:receivable_account_id)
    AccountingModule::Account.where(id: ids.uniq.compact.flatten)
  end

  def work_order_payments
    #
  end
	def self.with_credits
    all.select{ |a| a.with_credits? }
  end
  def last_updated_at
    if line_items.present?
      line_items.last.created_at
    else
      created_at
    end
  end
  def name
    full_name
  end
  def full_name
		"#{first_name} #{last_name}"
	end
	def purchases_count
		orders.count
	end

  def accounts_receivable
    total_sales_receivable +
    total_work_orders_receivable
    # other_credits_total +
    # credit_sales_order_accounts_receivable_total +
    # credit_repair_services_accounts_receivable_total
  end
  def total_receivables
    total_sales_receivable +
    total_work_orders_receivable
  end

  def total_sales_receivable
    orders.total_receivables
  end
  def total_work_orders_receivable
    work_orders.total_receivables
  end


  def credit_sales_order_accounts_receivable_total
    total = []
    sales_orders.each do |order|
      total << StoreFront.receivable_accounts.debits_balance(commercial_document_id: order.id, commercial_document_type: "Order")
    end
    total.sum
  end
  def other_credits_total
    StoreFront.receivable_accounts.debits_balance(commercial_document_id: self.id, commercial_document_type: 'Customer')
  end
  def other_credits
    StoreFront.receivable_accounts.debit_entries.where(commercial_document_id: self.id, commercial_document_type: "Customer")
  end


  def credit_repair_services_accounts_receivable_total
    work_orders.sum(&:accounts_receivable_total)
  end

  def payments_total
    credit_sales_order_payments_total +
    credit_repair_services_payments_total
  end

  def credit_sales_order_payments_total
    total = []
    sales_orders.each do |order|
      total << StoreFront.receivable_accounts.credits_balance(commercial_document_id: order.id, commercial_document_type: "Order")
    end
    total.sum
  end

  def credit_repair_services_payments_total
    total = []
    work_orders.each do |order|
      total << StoreFront.receivable_accounts.credits_balance(commercial_document_id: order.id, commercial_document_type: "WorkOrder")
    end
    total.sum
  end

  def balance_total
    accounts_receivable - payments_total
  end

  def with_credits?
    balance_total > 0
  end

  def payment_entries
    (other_payments + credit_sales_order_payments.to_a + payment_reversals.to_a).uniq
  end

  # Credit payments posted against this customer's sales orders. These
  # entries are keyed to the order (commercial_document = Order), so
  # other_payments (keyed to the customer) misses them.
  def credit_sales_order_payments
    account_ids = sales_orders.pluck(:receivable_account_id).compact.uniq
    return AccountingModule::Entry.none if account_ids.empty?

    AccountingModule::Entry.where(
      id: AccountingModule::CreditAmount.where(account_id: account_ids).select(:entry_id)
    )
  end

  # Reversal (VOID) entries posted against this customer's payments,
  # keyed either to the customer or to one of its sales orders.
  # NOTE: polymorphic docs for STI orders store the base class name
  # ("Order"), not "StoreFrontModule::Orders::SalesOrder". Old payment
  # entries may also have no document at all (nil); their reversals are
  # picked up via the order receivable accounts they touch.
  def payment_reversals
    order_ids = sales_orders.ids
    account_ids = sales_orders.pluck(:receivable_account_id).compact.uniq
    scope = AccountingModule::Entry.where(commercial_document: self)
    if order_ids.any?
      scope = scope.or(
        AccountingModule::Entry.where(
          commercial_document_type: "Order",
          commercial_document_id: order_ids
        )
      )
    end
    if account_ids.any?
      scope = scope.or(
        AccountingModule::Entry.where(commercial_document_type: nil).where(
          id: AccountingModule::Amount.where(account_id: account_ids).select(:entry_id)
        )
      )
    end
    scope.where("description LIKE ?", "#{AccountingModule::Entry::VOID_DESCRIPTION_PREFIX}%")
  end

  def other_payments
    payments = []
    User.cash_on_hand_accounts.each do |cash_account|
      cash_account.debit_entries.where(commercial_document: self).each do |payment|
        payments << payment
      end
    end
    payments
  end
  private
  def set_account_number
    self.account_number||= SecureRandom.uuid
  end

  def set_default_image
    if !avatar.attached?
      self.avatar.attach(io: File.open(Rails.root.join('app', 'assets', 'images', 'default.png')), filename: 'default-image.png', content_type: 'image/png')
    end
  end

  def normalize_name
    self.first_name = first_name.downcase.strip if first_name.present?
    self.last_name = last_name.downcase.strip if last_name.present?
  end
end