module CashRegisterSessions
  # Idempotent: one session per cashier per day. Re-sign-in resumes it.
  # Auto-closes any stale open session from a previous day.
  class OpenForDay
    attr_reader :employee, :date

    def initialize(employee:, date: Date.current)
      @employee = employee
      @date = date
    end

    def self.call(employee:, date: Date.current)
      new(employee: employee, date: date).call
    end

    def call
      return nil unless openable?

      ActiveRecord::Base.transaction do
        auto_close_stale_sessions!
        find_or_build_session!
      end
    end

    private

    def openable?
      employee.present? && employee.cashier?
    end

    def cash_account
      employee.cash_on_hand_account
    end

    def auto_close_stale_sessions!
      employee.cash_register_sessions.open.where.not(session_date: date).find_each do |stale|
        CloseSession.call(session: stale, auto: true)
      end
    end

    def find_or_build_session!
      session = employee.cash_register_sessions.find_or_initialize_by(session_date: date)
      return session unless session.new_record?

      session.cash_account = cash_account
      return nil if session.cash_account.blank?

      session.store_front = employee.store_front
      session.business = employee.business
      session.opened_at ||= Time.zone.now
      session.opening_system_amount ||= cash_account.balance(to_date: date.beginning_of_day - 1.second)
      session.save!
      session
    end
  end
end
