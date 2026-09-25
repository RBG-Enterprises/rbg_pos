class AddCashRegisterSessionToVouchers < ActiveRecord::Migration[6.1]
  def change
    add_reference :vouchers, :cash_register_session, foreign_key: true, index: true
  end
end
