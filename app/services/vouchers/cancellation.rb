# frozen_string_literal: true

class Vouchers::Cancellation < ActiveInteraction::Base
  object :voucher

  def execute
    ApplicationRecord.transaction do
      delete_voucher
      delete_entry
    end
  end

  private

  def delete_entry
    voucher.entry&.destroy
  end

  def delete_voucher
    voucher.destroy
  end
end