class Supplier < ApplicationRecord
	include PgSearch::Model
  has_one_attached :avatar
	pg_search_scope :text_search, against: [:business_name, :owner_name, :contact_number]
  multisearchable against: [:business_name]
	validates :business_name, presence: true
  belongs_to :payable_account, class_name: "AccountingModule::Account", optional: true
	has_many :delivered_stocks, class_name: "Stock"
	has_many :entries, through: :delivered_stocks
  has_many :payments, as: :commercial_document, class_name: "AccountingModule::Entry"

  has_many :purchase_orders, class_name: "StoreFrontModule::Orders::PurchaseOrder", as: :supplier
  has_many :purchase_return_orders, class_name: "StoreFrontModule::Orders::PurchaseReturnOrder", as: :commercial_document

  has_many :vouchers, as: :payee
  has_many :voucher_amounts, class_name: "Vouchers::VoucherAmount", through: :vouchers
  def name
    business_name
  end

  def accounts_payable
    default_accounts_payable_account.debits_balance(commercial_document_id: self.id)
	end
  def accounts_payable_vouchers_total
    total = []
    vouchers.each do |voucher|
      total << default_accounts_payable_account.credits_balance(commercial_document_id: voucher.id)
    end
    total
  end

  def temporary_voucher_amounts
    voucher_amounts.where(voucher_id: nil)
  end
  def payments_total
    default_accounts_payable_account.credits_balance(commercial_document_id: self.id)
  end
  def balance_total
    default_accounts_payable_account.balance(commercial_document_id: self.id)

  end
  def default_accounts_payable_account
    return payable_account if payable_account.present?
    AccountingModule::Liability.find_by(name: 'Accounts Payable-Trade')
  end
end
