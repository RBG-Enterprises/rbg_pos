# frozen_string_literal: true

module CashRegisterSessions
  # Voids a same-day cash transfer (remittance / cash transfer) by posting
  # a contra entry that swaps debits and credits.
  #
  # Only proprietors may void, and only transfers entered today — so a
  # transfer sent to the wrong account can be cancelled out without rewriting
  # history. The original entry is kept; the void entry nets its effect to
  # zero within the same cash register session.
  class VoidTransfer
    class NotVoidable < StandardError; end

    attr_reader :entry, :current_user

    def initialize(entry:, current_user:)
      @entry = entry
      @current_user = current_user
    end

    def self.call(entry:, current_user:)
      new(entry: entry, current_user: current_user).call
    end

    def call
      validate_voidable!
      ActiveRecord::Base.transaction do
        AccountingModule::Entry.create!(
          recorder: current_user,
          commercial_document: entry.commercial_document,
          entry_date: Time.zone.now,
          reference_number: entry.reference_number,
          description: AccountingModule::Entry.void_description_for(entry),
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
      raise NotVoidable, "Only proprietors can void transfers." unless current_user.proprietor?
      raise NotVoidable, "Only cash transfers can be voided." unless entry.transfer?
      raise NotVoidable, "Only today's transfers can be voided." unless entry.entered_today?
      raise NotVoidable, "Void entries cannot be voided." if entry.void_entry?
      raise NotVoidable, "This transfer has already been voided." if entry.voided?
    end
  end
end
