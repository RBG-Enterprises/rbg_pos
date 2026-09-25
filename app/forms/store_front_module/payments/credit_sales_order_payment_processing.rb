module StoreFrontModule
  module Payments
    class CreditSalesOrderPaymentProcessing
      include ActiveModel::Model
      attr_accessor :employee_id, :order_id, :amount, :expense_amount, :expense_account_id, :date, :description, :reference_number, :cash_on_hand_account_id
      attr_reader :voucher
      validates :date, :order_id, :amount, :reference_number, presence: true
      validates :amount, numericality: true
      def process!
        ActiveRecord::Base.transaction do
          build_voucher
        end
        voucher
      end
      private
      def build_voucher
        accounts_receivable = find_order.default_receivable_account
        cash_on_hand_account = find_employee.cash_on_hand_account

        @voucher = Vouchers::CreditSalesPaymentVoucher.new(
          date: Voucher.transaction_time_for(date),
          payee: find_order.customer,
          commercial_document: find_order,
          description: description.presence || reference_number,
          reference_number: SecureRandom.uuid,
          account_number: SecureRandom.uuid,
          preparer: find_employee,
          cash_register_session: find_employee.current_cash_register_session
        )

        if expense_amount.to_f > 0 && expense_account_id.present?
          @voucher.voucher_amounts.build(amount: amount, account: cash_on_hand_account, amount_type: :debit)
          @voucher.voucher_amounts.build(amount: expense_amount, account_id: expense_account_id, amount_type: :debit)
          @voucher.voucher_amounts.build(amount: amount.to_f + expense_amount.to_f, account: accounts_receivable, amount_type: :credit)
        else
          @voucher.voucher_amounts.build(amount: amount, account: cash_on_hand_account, amount_type: :debit)
          @voucher.voucher_amounts.build(amount: amount, account: accounts_receivable, amount_type: :credit)
        end

        @voucher.save!
      end
      def find_employee
        User.find_by_id(employee_id)
      end
      def find_order
        StoreFrontModule::Orders::SalesOrder.find(order_id)
      end
    end
  end
end
