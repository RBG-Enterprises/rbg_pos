module RepairServicesModule
  class PaymentProcessing
    include ActiveModel::Model
    attr_accessor :description, :amount, :date, :employee_id, :customer_id, :work_order_id, :expense_amount, :expense_account_id
    attr_reader :voucher
    validates :description, :amount, :date, :customer_id, presence: true
    validates :amount, numericality: true

    def process!
      ActiveRecord::Base.transaction do
        build_voucher
      end
      voucher
    end

    private
    def build_voucher
      accounts_receivable = find_work_order.default_receivable_account
      cash_on_hand_account = find_employee.cash_on_hand_account

      @voucher = Vouchers::RepairPaymentVoucher.new(
        date: Voucher.transaction_time_for(date),
        payee: find_customer,
        commercial_document: find_work_order,
        description: description,
        reference_number: SecureRandom.uuid,
        account_number: SecureRandom.uuid,
        preparer: find_employee,
        cash_register_session: find_employee.current_cash_register_session
      )

      if expense_account_id.blank? && expense_amount.to_i.zero?
        @voucher.voucher_amounts.build(amount: amount, account: cash_on_hand_account, amount_type: :debit)
        @voucher.voucher_amounts.build(amount: amount, account: accounts_receivable, amount_type: :credit)
      else
        @voucher.voucher_amounts.build(amount: amount, account: cash_on_hand_account, amount_type: :debit)
        @voucher.voucher_amounts.build(amount: expense_amount, account_id: expense_account_id, amount_type: :debit)
        @voucher.voucher_amounts.build(amount: amount.to_f + expense_amount.to_f, account: accounts_receivable, amount_type: :credit)
      end

      @voucher.save!
    end
    def amount_less_expense
      amount.to_f - expense_amount.to_f
    end
    def find_employee
      User.find_by_id(employee_id)
    end
    def find_customer
      Customer.find_by_id(customer_id)
    end
    def find_work_order
      WorkOrder.find_by_id(work_order_id)
    end
  end
end
