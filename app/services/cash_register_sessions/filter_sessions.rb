# frozen_string_literal: true

# Scopes the cash register sessions index: proprietors/accountants see every
# session and may narrow by cashier and/or session date; everyone else
# only ever sees their own sessions.
class CashRegisterSessions::FilterSessions < ActiveInteraction::Base
  Result = Struct.new(:sessions, :can_filter_by_employee, keyword_init: true)

  object :current_user, class: "User"
  integer :employee_id, default: nil
  date :date, default: nil

  def execute
    Result.new(
      sessions: sessions_scope,
      can_filter_by_employee: can_filter_by_employee?
    )
  end

  private

  def can_filter_by_employee?
    current_user.proprietor? || current_user.accountant?
  end

  def sessions_scope
    scope = can_filter_by_employee? ? CashRegisterSession.recent : current_user.cash_register_sessions.recent
    scope = scope.where(employee_id: employee_id) if can_filter_by_employee? && employee_id.present?
    scope = scope.where(session_date: date) if date.present?
    scope.includes(:store_front, :cash_account, employee: { avatar_attachment: :blob })
  end
end
