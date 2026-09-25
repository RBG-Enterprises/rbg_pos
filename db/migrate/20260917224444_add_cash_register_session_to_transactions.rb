class AddCashRegisterSessionToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_belongs_to :orders, :cash_register_session, foreign_key: { to_table: :cash_register_sessions }
    add_belongs_to :entries, :cash_register_session, foreign_key: { to_table: :cash_register_sessions }
    add_belongs_to :cash_counts, :cash_register_session, foreign_key: { to_table: :cash_register_sessions }
  end
end
