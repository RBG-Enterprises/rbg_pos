# frozen_string_literal: true

module Customers
  class AccountMerging
    include ActiveModel::Model
    attr_accessor :old_customer_id, :new_customer_id

    def merge!
      ActiveRecord::Base.transaction do
        merge_accounts
      end
    end

    private

    def merge_accounts
      old_customer = Customer.find_by_id(old_customer_id)
      new_customer = Customer.find_by_id(new_customer_id)
      new_customer.orders      << old_customer.orders
      new_customer.payments    << old_customer.payments
      new_customer.work_orders << old_customer.work_orders
      new_customer.departments << old_customer.departments
      old_customer.destroy
    end
  end
end
