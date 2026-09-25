module CashCounts
  class CashCount < ApplicationRecord
    belongs_to :employee
    belongs_to :cash_register_session, optional: true

    before_validation :assign_cash_register_session, on: :create

    private

    def assign_cash_register_session
      return if cash_register_session_id.present?
      return if employee.blank?

      record_date = (date.presence && date.to_date) || Date.current
      self.cash_register_session =
        employee.cash_register_sessions.open.for_day(record_date).first ||
        employee.cash_register_sessions.open.recent.first
    rescue StandardError
      nil
    end
  end
end 
