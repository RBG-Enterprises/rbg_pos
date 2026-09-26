class User < ApplicationRecord
  include PgSearch::Model
  has_one_attached :avatar
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  belongs_to :branch,               optional: true
  belongs_to :store_front,          optional: true
  belongs_to :business,             optional: true
  belongs_to :section,              optional: true
  belongs_to :cash_on_hand_account, optional: true, class_name: "AccountingModule::Account"
  has_many :orders,                 foreign_key: 'employee_id'
  has_many :sales_orders,           class_name: "StoreFrontModule::Orders::SalesOrder", foreign_key: 'employee_id'
  has_many :technician_work_orders, foreign_key: 'technician_id'
  has_many :work_orders,            foreign_key: 'technician_id'
  has_many :entries,                class_name: "AccountingModule::Entry", foreign_key: 'recorder_id'
  has_many :fund_transfers,         class_name: "AccountingModule::Entry", as: :commercial_document
  has_many :actions_taken,          class_name: "ActionsTaken"
  has_many :employee_cash_accounts, class_name: "Employees::EmployeeCashAccount", foreign_key: 'employee_id'
  has_many :cash_accounts,          through: :employee_cash_accounts, class_name: "AccountingModule::Account", foreign_key: 'cash_account_id'
  has_many :voucher_amounts,        class_name: "Vouchers::VoucherAmount", foreign_key: 'recorder_id'
  has_many :cash_counts,            class_name: "CashCounts::CashCount", foreign_key: 'employee_id'
  has_many :user_store_fronts, dependent: :destroy
  has_many :accessible_store_fronts, through: :user_store_fronts, source: :store_front
  has_many :cash_register_sessions, class_name: "CashRegisterSession", foreign_key: 'employee_id'

  enum role: [:proprietor, :sales_clerk, :technician, :accountant, :warehouse_clerk]

  pg_search_scope :text_search, against: [:first_name, :last_name, :email]

  delegate :balance, to: :default_cash_on_hand_account, prefix: true, allow_nil: true
  before_save :set_default_image

  def self.active
    where(deactivated_at: nil)
  end

  def self.cash_on_hand_accounts
    ids = pluck(:cash_on_hand_account_id)
    AccountingModule::Account.where(id: ids.uniq.compact.flatten)
  end

  def active?
    deactivated_at.blank?
  end

  # A cashier is anyone entrusted with a cash drawer, i.e. anyone with a
  # cash-on-hand account assigned — regardless of role name.
  def cashier?
    cash_on_hand_account.present?
  end

  def name_and_store_front
    "#{full_name} - #{store_front.name}"
  end

  # Every store front this user is allowed to switch to: explicitly granted
  # access plus their home store front (so legacy users keep working).
  def switchable_store_fronts
    StoreFront.where(id: ([store_front_id] + user_store_fronts.select(:store_front_id).map(&:store_front_id)).compact.uniq)
  end

  def can_access_store_front?(store_front)
    return false if store_front.nil?
    store_front.id == store_front_id || user_store_fronts.exists?(store_front_id: store_front.id)
  end

  def self.employee_for(cash_on_hand_account)
    where(cash_on_hand_account: cash_on_hand_account).first
  end

  def full_name
  	"#{first_name} #{last_name}"
  end
  def name
    full_name
  end
  def received_cash_transfers(options={})
    amounts = []
    cash_on_hand_account.debit_amounts.entered_on(options).each do |amount|
      unless (User.cash_on_hand_accounts.ids & amount.entry.credit_amounts.pluck(:account_id)).empty?
        amounts << amount
      end
    end
    amounts
  end

  def remittances(options={})
    amounts = []
    cash_on_hand_account.credit_amounts.entered_on(options).each do |amount|
      unless (User.cash_on_hand_accounts.ids & amount.entry.debit_amounts.pluck(:account_id)).empty?
        amounts << amount
      end
    end
    amounts
  end

  def cash_on_hand_account_balance
    default_cash_on_hand_account.balance(recorder_id: self.id)
  end

  def current_cash_register_session
    cash_register_sessions.open.for_day(Date.current).first ||
      cash_register_sessions.open.recent.first
  end

  def cash_register_session_for(date = Date.current)
    cash_register_sessions.for_day(date).first
  end

  def default_cash_on_hand_account
    if cash_on_hand_account.present?
      cash_on_hand_account
    else
      default_cash_on_hand_account_for(self)
    end
  end

  private
  def default_cash_on_hand_account_for(employee)
    if employee.proprietor?
      AccountingModule::Asset.find_by(name: "Cash on Hand")
    elsif employee.sales_clerk?
      AccountingModule::Asset.find_by(name: "Cash on Hand (Cashier)")
    end
  end

  def set_default_image
    if !avatar.attached?
      self.avatar.attach(io: File.open(Rails.root.join('app', 'assets', 'images', 'default.png')), filename: 'default-image.png', content_type: 'image/png')
    end
  end
end
