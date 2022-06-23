module Employees
  class EmployeeCashAccount < ApplicationRecord
    belongs_to :employee,     class_name: "User", foreign_key: 'employee_id', inverse_of: :employee_cash_accounts
    belongs_to :cash_account, class_name: "AccountingModule::Account", foreign_key: 'cash_account_id', inverse_of: :employee_cash_accounts

    validates :cash_account_id, uniqueness: { scope: :employee_id }

    def self.cash_accounts
      cash_accounts = pluck(:cash_account_id)
      AccountingModule::Account.where(id: cash_accounts)
    end
  end
end
