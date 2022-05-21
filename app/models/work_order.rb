class WorkOrder < ApplicationRecord
  include PgSearch::Model
  enum status: [:received, :work_in_progress, :done,  :released, :return_to_owner]

  pg_search_scope :text_search, against: [:service_number, :reported_problem, :physical_condition, :customer_name, :product_name],
  :associated_against => { :charge_invoice => [:number], product_unit: [:description, :model_number, :serial_number] }
  multisearchable :against => [:description, :model_number, :serial_number, :reported_problem, :physical_condition, :service_number, :customer_name, :product_name]

  belongs_to :receivable_account,      class_name: 'AccountingModule::Account'
  belongs_to :sales_revenue_account,   class_name: 'AccountingModule::Account'
  belongs_to :sales_discount_account,  class_name: 'AccountingModule::Account'
  belongs_to :service_revenue_account, class_name: 'AccountingModule::Account'
  belongs_to :technician,              class_name: 'User', foreign_key: 'technician_id'
  belongs_to :product_unit
  belongs_to :department,              optional: true
  belongs_to :work_order_category,     optional: true
  belongs_to :supplier,                optional: true
  belongs_to :section,                 optional: true
  belongs_to :customer
  belongs_to :store_front
  has_one :charge_invoice,              as: :invoiceable, class_name: "Invoices::ChargeInvoice"
  has_many :accessories
  has_many :technician_work_orders,     dependent: :destroy
  has_many :technicians,                through: :technician_work_orders
  has_many :work_order_updates,         as: :updateable, class_name: "Post", dependent: :destroy
  has_many :diagnoses,                  as: :updateable, class_name: 'Diagnosis', dependent: :destroy
  has_many :actions_taken,              as: :updateable, class_name: 'ActionTaken', dependent: :destroy
  has_many :work_order_service_charges, class_name: 'WorkOrders::WorkOrderServiceCharge', dependent: :destroy
  has_many :service_charges,            through: :work_order_service_charges
  has_many :sales_orders,               class_name: "StoreFrontModule::Orders::SalesOrder", as: :commercial_document, dependent: :destroy
  has_many :sales_order_line_items,     through: :sales_orders, class_name: "StoreFrontModule::LineItems::SalesOrderLineItem"
  has_many :accessories,                dependent: :destroy
  has_many :entries,                    class_name: "AccountingModule::Entry", through: :receivable_account

  validates :description, :physical_condition, :reported_problem, presence: true
  validates :customer_id, :date_received, presence: true

  delegate :description, :model_number, :serial_number, to: :product_unit, allow_nil: true
  delegate :full_name, :address, :contact_number, to: :customer, allow_nil: true, prefix: true
  delegate :avatar, :full_name, to: :customer
  delegate :number, to: :charge_invoice, prefix: true, allow_nil: true
  delegate :business, to: :store_front
  delegate :name,  to: :department, prefix: true, allow_nil: true

  after_commit :set_customer_name, :set_product_name,  on: [:create, :update]
  after_commit :set_release_date

  def self.receivable_accounts
    ids = pluck(:receivable_account_id)
    AccountingModule::Account.where(id: ids.uniq.compact.flatten)
  end

  def self.total_receivables(args = {})
    receivable_accounts.balance(args)
  end

  def self.done_and_rto
    where(status: 'done').or(self.where(status: 'return_to_owner'))
  end

  def self.payment_entries
    receivable_accounts.credit_entries
  end

  def name
    "#{product_name}"
  end

  def self.total_charges_cost(args={} ) #refactor
    if args[:from_date] && args[:to_date]
       date_range = DateRange.new(from_date: args[:from_date], to_date: args[:to_date])
        where('date_received' => (date_range.range)).
        sum(&:total_charges_cost)
    else
      all.sum(&:total_charges_cost)
    end
  end

  def self.total_spare_parts_cost(hash ={} ) #refactor
    if hash[:from_date] && hash[:to_date]
       from_date = hash[:from_date].kind_of?(DateTime) ? hash[:from_date] : DateTime.parse(hash[:from_date])
        to_date = hash[:to_date].kind_of?(DateTime) ? hash[:to_date] : DateTime.parse(hash[:to_date])
        where('created_at' => (from_date.beginning_of_day)..(to_date.end_of_day)).sum(&:total_spare_parts_cost)
    else
      all.sum(&:total_spare_parts_cost)
    end
  end
  def self.total_service_charges_cost(hash ={} ) #refactor
    if hash[:from_date] && hash[:to_date]
       from_date = hash[:from_date].kind_of?(DateTime) ? hash[:from_date] : DateTime.parse(hash[:from_date])
        to_date = hash[:to_date].kind_of?(DateTime) ? hash[:to_date] : DateTime.parse(hash[:to_date])
        where('created_at' => (from_date.beginning_of_day)..(to_date.end_of_day)).sum(&:total_service_charges_cost)
    else
      all.sum(&:total_service_charges_cost)
    end
  end
  def self.from(hash={}) #refactor
    if hash[:from_date] && hash[:to_date]
      date_range = DateRange.new(from_date: hash[:from_date], to_date: hash[:to_date])
      where('date_received' => date_range.start_date..date_range.end_date)
    else
      all
    end
  end

  def self.received_at(from_date:, to_date:)
    date_range = DateRange.new(from_date: from_date, to_date: to_date)
    where('date_received' => date_range.start_date..date_range.end_date)
  end

  def self.released_on(from_date:, to_date:)
    date_range = DateRange.new(from_date: from_date, to_date: to_date)
    where('release_date' => date_range.start_date..date_range.end_date)
  end

  def self.payments
    select{ |a| a.payments }
  end

  def self.payments_total
    all.sum(&:payments_total)
  end

  def technicians_name
    technicians.map{|a| a.full_name }.join(",")
  end

  # def accounts_receivable
  #   spare_parts = entries.work_order_credit.map{|a| a.debit_amounts.distinct.pluck(:amount).sum}.sum
  #   service_charges = entries.work_order_service_charge.map{|a| a.debit_amounts.distinct.pluck(:amount).sum}.sum
  #   spare_parts + service_charges
  # end
  def accounts_receivable_total
    receivable_account.debits_balance
  end
  def accounts_receivable_less_sales_returns_total
    receivable_account.debits_balance - sales_returns_total
  end

  def sales_returns_total
    receivable_account.credits_balance - cash_payments_total
  end

  def cash_payments_total
    receivable_account.credit_entries.map{ |entry| entry.amounts.where(account_id: User.cash_on_hand_accounts.ids).total }.sum
  end

  def refunds_total
  end

  def spare_parts_receivable
    receivable_account.debits_balance
  end

  def service_charges_receivable
    balance = []
    work_order_service_charges.each do |service_charge|
      balance << service_revenue_account.credit_amounts.where(commercial_document: service_charge).sum(&:amount)
    end
    balance.sum
  end

  def payment_entries
    receivable_account.amounts.where(commercial_document_id: self.id, commercial_document_type: "WorkOrder")
  end



  def payments_total
    receivable_account.credits_balance
  end

  def service_charge_payments
    payments_total - total_spare_parts_cost
  end

  def incentivized_charges
    service_charge_payments / technicians.count
  end


  def balance_total
    receivable_account.balance
  end

  def discounts_total
    default_sales_discount_account.debits_balance(commercial_document_id: self.id, commercial_document_type: "WorkOrder")
  end

  def total_spare_parts_cost
    sales_revenue_account.balance
  end

  def total_service_charges_cost
    service_revenue_account.balance
  end

  def total_charges_cost
    total_service_charges_cost + total_spare_parts_cost
  end
  def add_technician(technician)
    self.technician_work_orders.find_or_create_by(technician: technician)
  end
  def elapsed_time
    (self.created_at - Time.zone.now) /86400
  end

  def destroy_entry_for(options={})
    order = options[:order]
    entry = AccountingModule::Amount.where(commercial_document_id: order.id, commercial_document_type: order.class.to_s).first
    if entry.present?
      entry.destroy
    end
  end

  def default_receivable_account
    if receivable_account.blank?
      store_front.receivable_account
    else
      receivable_account
    end
  end

  def default_sales_discount_account
    if sales_discount_account.blank?
      store_front.sales_discount_account
    else
      sales_discount_account
    end
  end

  def default_service_revenue_account
    if service_revenue_account.blank?
      store_front.service_revenue_account
    else
      service_revenue_account
    end
  end

  private

  def set_customer_name
    self.customer_name = self.customer.full_name
  end

  def set_product_name
    self.product_name = self.product_unit.description
  end
  def set_release_date
    if released? && release_date.blank?
      self.release_date = Time.zone.now
      self.save!
    end
  end
end
