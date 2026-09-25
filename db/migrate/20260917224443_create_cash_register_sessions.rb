class CreateCashRegisterSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :cash_register_sessions do |t|
      t.belongs_to :employee, foreign_key: { to_table: :users }, null: false
      t.belongs_to :cash_account, foreign_key: { to_table: :accounts }, null: false
      t.belongs_to :store_front, foreign_key: true
      t.belongs_to :business, foreign_key: true
      t.date :session_date, null: false
      t.datetime :opened_at
      t.datetime :closed_at
      t.integer :status, default: 0, null: false
      t.decimal :opening_declared_amount, precision: 15, scale: 2
      t.decimal :opening_system_amount, precision: 15, scale: 2
      t.decimal :closing_declared_amount, precision: 15, scale: 2
      t.decimal :closing_system_amount, precision: 15, scale: 2
      t.decimal :variance_amount, precision: 15, scale: 2
      t.boolean :auto_closed, default: false, null: false
      t.text :opening_note
      t.text :closing_note

      t.timestamps
    end

    add_index :cash_register_sessions, [:employee_id, :session_date], unique: true
    add_index :cash_register_sessions, [:employee_id, :status]
  end
end
