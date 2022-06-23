# frozen_string_literal: true

require "rails_helper"

module Employees
  describe EmployeeCashAccount do
    describe "associations" do
      it { is_expected.to belong_to :employee }
      it { is_expected.to belong_to :cash_account }
    end

    it '.cash_accounts' do
      cash_account_1 = create(:asset)
      cash_account_2 = create(:asset)
      cash_account_3 = create(:asset)
      em_cash_account_1 = create(:employee_cash_account, cash_account: cash_account_1)
      em_cash_account_2 = create(:employee_cash_account, cash_account: cash_account_2)

      expect(described_class.cash_accounts).to include(cash_account_1)
      expect(described_class.cash_accounts).to include(cash_account_2)
      expect(described_class.cash_accounts).not_to include(cash_account_3)
    end
  end
end
