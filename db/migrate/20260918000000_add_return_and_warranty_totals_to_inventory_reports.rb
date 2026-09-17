# frozen_string_literal: true

class AddReturnAndWarrantyTotalsToInventoryReports < ActiveRecord::Migration[6.1]
  def change
    add_column :inventory_reports, :sales_returns, :decimal, default: "0.0", null: false
    add_column :inventory_reports, :purchase_returns, :decimal, default: "0.0", null: false
    add_column :inventory_reports, :for_warranties, :decimal, default: "0.0", null: false
  end
end
