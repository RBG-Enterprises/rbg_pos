# frozen_string_literal: true

class CreateInventoryReports < ActiveRecord::Migration[6.1]
  def change
    create_table :inventory_reports do |t|
      t.references :stock, null: false, foreign_key: true, index: false
      t.references :product, null: false, foreign_key: true
      t.references :store_front, null: false, foreign_key: true
      t.decimal :purchases, default: "0.0", null: false
      t.decimal :sales, default: "0.0", null: false
      t.decimal :spoilage, default: "0.0", null: false
      t.decimal :internal_use, default: "0.0", null: false
      t.decimal :transfers, default: "0.0", null: false
      t.decimal :available, default: "0.0", null: false

      t.timestamps
    end

    add_index :inventory_reports, :stock_id, unique: true
  end
end
