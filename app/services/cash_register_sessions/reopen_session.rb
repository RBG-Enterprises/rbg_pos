module CashRegisterSessions
  # Reopens a same-day closed session (e.g. cashier closed then logged
  # back in the same day). Resets the closing count to zero so the new
  # shift starts clean; opening float and system amounts are preserved.
  class ReopenSession
    class NotReopenable < StandardError; end

    attr_reader :session

    def initialize(session:)
      @session = session
    end

    def self.call(session:)
      new(session: session).call
    end

    def call
      raise NotReopenable, "Session is already open." if session.open?
      unless session.session_date == Date.current
        raise NotReopenable, "Only today's session can be reopened."
      end

      ActiveRecord::Base.transaction do
        session.status = :open
        session.closed_at = nil
        session.closing_declared_amount = 0
        session.closing_system_amount = nil
        session.variance_amount = nil
        session.closing_note = nil
        session.auto_closed = false
        session.save!
      end
      session
    end
  end
end
