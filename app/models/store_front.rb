class StoreFront < ApplicationRecord
  belongs_to :business
  belongs_to :service_receivable_account_category, class_name: 'AccountingModule::AccountCategory', optional: true
  belongs_to :sales_revenue_account_category,      class_name: 'AccountingModule::AccountCategory', optional: true
  belongs_to :merchandise_inventory_account,       class_name: "AccountingModule::Account", foreign_key: 'merchandise_inventory_account_id'
  belongs_to :sales_account,                       class_name: "AccountingModule::Account", foreign_key: 'sales_account_id', optional: true
  belongs_to :sales_discount_account,              class_name: "AccountingModule::Account", foreign_key: 'sales_discount_account_id', optional: true
  belongs_to :sales_return_account,                class_name: "AccountingModule::Account", foreign_key: 'sales_return_account_id', optional: true
  belongs_to :cost_of_goods_sold_account,          class_name: "AccountingModule::Account", foreign_key: 'cost_of_goods_sold_account_id'
  belongs_to :receivable_account,                  class_name: "AccountingModule::Account", foreign_key: 'receivable_account_id', optional: true
  belongs_to :internal_use_account,                class_name: "AccountingModule::Account", foreign_key: 'internal_use_account_id', optional: true
  belongs_to :purchase_return_account,             class_name: "AccountingModule::Account", foreign_key: 'purchase_return_account_id', optional: true
  belongs_to :spoilage_account,                    class_name: "AccountingModule::Account", foreign_key: 'spoilage_account_id', optional: true
  belongs_to :service_revenue_account,             class_name: "AccountingModule::Account", foreign_key: 'service_revenue_account_id', optional: true
  has_many :sales_orders,                          class_name: "StoreFrontModule::Orders::SalesOrder", foreign_key: 'store_front_id'
  has_many :purchase_orders,                       class_name: "StoreFrontModule::Orders::PurchaseOrder", foreign_key: 'store_front_id'
  has_many :purchase_order_line_items,             through: :purchase_orders, class_name: "StoreFrontModule::LineItems::PurchaseOrderLineItem"
  has_many :delivered_stock_transfer_orders,       class_name: "StoreFrontModule::Orders::PurchaseOrder", as: :supplier
  has_many :delivered_stock_transfers,             through: :delivered_stock_transfer_orders, source: :purchase_order_line_items
  has_many :sales_order_line_items,                through: :sales_orders, class_name: "StoreFrontModule::LineItems::SalesOrderLineItem"
  has_many :work_orders
  has_many :selling_prices,                        class_name: "StoreFrontModule::SellingPrice"
  has_many :employees,                             class_name: 'User'
  has_many :store_front_accounts,                  class_name: 'StoreFronts::StoreFrontAccount'
  has_many :accounts,                              through: :store_front_accounts
  has_many :stocks,                                class_name: 'StoreFronts::Stock'
  has_many :level_one_account_categories,          class_name: 'AccountingModule::AccountCategories::LevelOneAccountCategory'
  validates :name, presence: true

  delegate :name, to: :business, prefix: true

  def self.active
    where(deactivated_at: nil)
  end

  def self.service_receivable_account_categories
    ids = pluck(:service_receivable_account_category_id)
    AccountingModule::AccountCategory.where(id: ids.uniq.compact.flatten)
  end

  def self.sales_revenue_account_categories
    ids = pluck(:sales_revenue_account_category_id)
    AccountingModule::AccountCategory.where(id: ids.uniq.compact.flatten)
  end

  def payable_account
    merchandise_inventory_account
  end

  def self.receivable_accounts
    ids = pluck(:receivable_account_id)
    AccountingModule::Account.where(id: ids)
  end

  def self.sales_accounts
    ids = pluck(:sales_account_id)
    AccountingModule::Account.where(id: ids)
  end

  def self.sales_discount_accounts
    ids = pluck(:sales_discount_account_id)
    AccountingModule::Account.where(id: ids)
  end
end
