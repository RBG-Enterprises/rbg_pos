# frozen_string_literal: true

module Customers
  # Voids a customer account payment by posting a contra (reversal)
  # entry that swaps debits and credits.
  #
  # Covers both customer-level payments (commercial_document = Customer)
  # and credit payments posted against the customer's sales orders
  # (commercial_document = Order). The original entry is kept; the void
  # entry nets its effect to zero so history is preserved.
  class VoidPayment
    class NotVoidable < StandardError; end

    attr_reader :customer, :entry, :current_user, :note

    def initialize(customer:, entry:, current_user:, note: nil)
      @customer = customer
      @entry = entry
      @current_user = current_user
      @note = note
    end

    def self.call(customer:, entry:, current_user:, note: nil)
      new(customer: customer, entry: entry, current_user: current_user, note: note).call
    end

    def call
      validate_voidable!
      ActiveRecord::Base.transaction do
        AccountingModule::Entry.create!(
          recorder: current_user,
          # Old payment entries may have no document (nil); fall back to
          # the customer so the reversal stays linked and listable.
          commercial_document: entry.commercial_document || customer,
          entry_date: Time.zone.now,
          reference_number: entry.reference_number,
          description: reversal_description,
          cash_register_session: entry.cash_register_session,
          credit_amounts_attributes: entry.debit_amounts.map do |amount|
            { amount: amount.amount, account_id: amount.account_id }
          end,
          debit_amounts_attributes: entry.credit_amounts.map do |amount|
            { amount: amount.amount, account_id: amount.account_id }
          end
        )
      end
    end

    private

    def validate_voidable!
      raise NotVoidable, "Only proprietors can void payments." unless current_user.proprietor?
      raise NotVoidable, "Payment does not belong to this customer." unless payment_entry_for_customer?
      raise NotVoidable, "Void entries cannot be voided." if entry.void_entry?
      raise NotVoidable, "This payment has already been voided." if entry.voided?
      raise NotVoidable, "A void note is required." if note.blank?
    end

    # The note is stored in the reversal entry's description (no new
    # column); truncated to fit the 255-char limit.
    def reversal_description
      base = AccountingModule::Entry.void_description_for(entry)
      "#{base} (Note: #{note.to_s.strip})".truncate(255)
    end

    def payment_entry_for_customer?
      return true if entry.commercial_document == customer

      account_ids = customer.sales_orders.pluck(:receivable_account_id).compact
      return false if account_ids.empty?

      AccountingModule::CreditAmount.where(account_id: account_ids, entry_id: entry.id).exists? ||
        AccountingModule::DebitAmount.where(account_id: account_ids, entry_id: entry.id).exists?
    end
  end
end
