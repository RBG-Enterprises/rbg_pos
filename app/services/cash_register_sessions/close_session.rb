module CashRegisterSessions
  # Closes a session: snapshots expected cash, computes variance vs counted.
  class CloseSession
    attr_reader :session, :counted_amount, :auto

    def initialize(session:, counted_amount: nil, closing_note: nil, auto: false)
      @session = session
      @counted_amount = counted_amount
      @closing_note = closing_note
      @auto = auto
    end

    def self.call(session:, counted_amount: nil, closing_note: nil, auto: false)
      new(session: session, counted_amount: counted_amount, closing_note: closing_note, auto: auto).call
    end

    def call
      return session if session.closed?

      ActiveRecord::Base.transaction do
        session.closing_declared_amount = counted_amount if counted_amount.present?
        session.closing_system_amount = session.expected_cash
        session.variance_amount = (session.closing_declared_amount || session.closing_system_amount) - session.closing_system_amount
        session.closing_note = @closing_note if @closing_note.present?
        session.auto_closed = true if auto
        session.closed_at = Time.zone.now
        session.status = :closed
        session.save!
      end
      session
    end
  end
end
