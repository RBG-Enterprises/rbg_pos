# frozen_string_literal: true

class AddCountAdjustmentToStocks < ActiveRecord::Migration[6.1]
  def change
    add_column :stocks, :count_adjustment, :decimal, default: "0.0", null: false
  end
end
