# frozen_string_literal: true

# Derived per-stock inventory report rebuilt periodically from LineItem records.
# LineItem is the source of truth; this table is never written by transactions.
class InventoryReport < ApplicationRecord
  belongs_to :stock, class_name: "StoreFronts::Stock"
  belongs_to :product
  belongs_to :store_front, class_name: "StoreFront"
  # Spec terminology: Branch == StoreFront in this codebase.
  belongs_to :branch, class_name: "StoreFront", foreign_key: "store_front_id"

  validates :stock_id, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :store_front_id, presence: true

  # Branch alias so `report.branch_id` works alongside `report.store_front_id`.
  def branch_id
    store_front_id
  end

  def branch_id=(value)
    self.store_front_id = value
  end
end
