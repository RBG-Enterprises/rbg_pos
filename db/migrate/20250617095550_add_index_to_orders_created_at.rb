# frozen_string_literal: true

class AddIndexToOrdersCreatedAt < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index :orders, :created_at, algorithm: :concurrently
  end

  def down
    remove_index :orders, column: :created_at
  end
end
