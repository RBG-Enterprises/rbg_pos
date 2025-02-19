# frozen_string_literal: true

class AddIsProcessedToStocks < ActiveRecord::Migration[6.1]
  def change
    add_column :stocks, :is_processed, :boolean, default: false, null: false
    add_index :stocks, :is_processed
  end
end
